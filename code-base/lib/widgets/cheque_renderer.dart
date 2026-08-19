import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/cheque_template.dart';
import '../models/cheque_template_field.dart';

/// Reusable, database-driven cheque renderer.
///
/// Draws a [ChequeTemplate]'s background image on a Stack and places each
/// [ChequeTemplateField] at its stored (x, y) canvas coordinates. The canvas
/// is a fixed-size container matching `canvasWidth` x `canvasHeight` and is
/// scaled to fit the available space via [FittedBox], so positions stay
/// accurate on every device.
///
/// Used both by the admin template editor (live preview with dummy data) and
/// the real write/preview/print screens (real data), so what the admin sees
/// is exactly what gets produced.
class ChequeRenderer extends StatelessWidget {
  final ChequeTemplate template;
  final List<ChequeTemplateField> fields;

  final String bankKey;
  final String bankName;
  final String branch;
  final DateTime date;
  final String payee;
  final double amount;
  final String amountInWords;
  final String status;
  final bool crossed;

  /// When true (template editor preview), empty values are replaced with
  /// sample placeholders so the admin can judge layout and wrapping.
  final bool isPreview;

  /// Template-editor support: id of the currently selected field and a tap
  /// callback. When set, fields render a dashed blue selection box and the
  /// canvas forwards taps so the editor can select fields directly.
  final int? selectedFieldId;
  final ValueChanged<ChequeTemplateField>? onFieldTap;

  const ChequeRenderer({
    super.key,
    required this.template,
    required this.fields,
    this.bankKey = '',
    this.bankName = '',
    this.branch = '',
    required this.date,
    this.payee = '',
    this.amount = 0,
    this.amountInWords = '',
    this.status = 'Issued',
    this.crossed = false,
    this.isPreview = false,
    this.selectedFieldId,
    this.onFieldTap,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: Container(
        width: template.canvasWidth,
        height: template.canvasHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF1A1D26), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _background(),
            if (crossed) _crossedMarking(),
            ..._buildFields(context),
          ],
        ),
      ),
    );
  }

  Widget _background() {
    final path = template.backgroundImagePath;
    Widget fallback = Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: const Icon(Icons.receipt_long_rounded,
          size: 64, color: Color(0xFFD1D5DB)),
    );

    if (path.isEmpty) return fallback;

    final Widget image = template.backgroundIsDataUri
        ? Image.memory(_decodeDataUri(path), fit: BoxFit.fill)
        : Image.asset(path, fit: BoxFit.fill);

    return Positioned.fill(
      child: image,
    );
  }

  List<Widget> _buildFields(BuildContext context) {
    return fields.map((f) {
      final Widget child = switch (f.fieldName) {
        ChequeTemplateFieldName.bankLogo => _bankLogo(f),
        ChequeTemplateFieldName.bankName => _text(
            f,
            bankName.isNotEmpty ? bankName : (isPreview ? 'Bank Name' : ''),
          ),
        ChequeTemplateFieldName.digitalStamp => _digitalStamp(f),
        ChequeTemplateFieldName.branch =>
          _chequeLine(f, 'BRANCH', branch, isPreview: isPreview),
        ChequeTemplateFieldName.date => _chequeLine(
            f,
            'DATE',
            DateFormat('dd / MM / yyyy').format(date),
            isPreview: isPreview,
          ),
        ChequeTemplateFieldName.payee =>
          _chequeLine(f, 'PAY', payee, isPreview: isPreview),
        ChequeTemplateFieldName.amountNumeric => _text(
            f,
            'ETB ${NumberFormat('#,##0.00', 'en_US').format(amount)}',
          ),
        ChequeTemplateFieldName.amountWords => _chequeLine(
            f,
            'THE SUM OF',
            amountInWords,
            isPreview: isPreview,
          ),
      };
      final selectable = _selectable(f, child);
      return f.fieldType == ChequeTemplateFieldType.image
          ? _positionedImage(f, child: selectable)
          : _positioned(f, child: selectable);
    }).toList();
  }

  /// A cheque line: small uppercase label on top, then the value — or a blank
  /// writing space when previewing an empty template. This mirrors a real
  /// leaf ("PAY  ______", "DATE  ______", …).
  Widget _chequeLine(
    ChequeTemplateField f,
    String label,
    String value, {
    required bool isPreview,
  }) {
    final effective = isPreview ? '' : value;
    final align = switch (f.alignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
    final weight = switch (f.fontWeight) {
      'w500' => FontWeight.w500,
      'w600' => FontWeight.w600,
      'w700' => FontWeight.w700,
      'bold' => FontWeight.bold,
      _ => FontWeight.normal,
    };
    final lineW = f.maxWidth ?? 260;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: (f.fontSize ?? 13) * 0.62,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9CA3AF),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          width: lineW,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (effective.isNotEmpty)
                Text(
                  effective,
                  textAlign: align,
                  maxLines: f.maxWidth != null ? 3 : 1,
                  overflow: f.maxWidth != null
                      ? TextOverflow.ellipsis
                      : TextOverflow.clip,
                  style: TextStyle(
                    fontSize: f.fontSize ?? 13,
                    fontWeight: weight,
                    color: _fieldColor(f),
                    fontStyle:
                        f.italic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              Container(
                width: lineW,
                height: 1.5,
                color: const Color(0xFFB9BEC7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Wraps a field's child in a Positioned at its canvas coordinates. A
  /// [maxWidth] constraint is applied so long values (amountWords) wrap.
  /// Converts stored Y (distance from bottom) to top-down position.
  double _topFromBottom(double y, {double? fieldHeight}) {
    final h = fieldHeight ?? 20;
    return template.canvasHeight - y - h;
  }

  Widget _positioned(ChequeTemplateField f, {required Widget child}) {
    return Positioned(
      left: f.x,
      top: _topFromBottom(f.y, fieldHeight: 40),
      width: f.maxWidth ?? 300,
      child: child,
    );
  }

  Widget _positionedImage(ChequeTemplateField f, {required Widget child}) {
    return Positioned(
      left: f.x,
      top: _topFromBottom(f.y, fieldHeight: f.imageHeight ?? 48),
      width: f.imageWidth,
      height: f.imageHeight,
      child: child,
    );
  }

  /// Wraps a field so the editor can select it: tap-to-select plus a dashed
  /// blue selection box with a field-name label when it is the active one.
  Widget _selectable(ChequeTemplateField f, Widget child) {
    return GestureDetector(
      onTap: onFieldTap == null ? null : () => onFieldTap!(f),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (selectedFieldId == f.id) _selectionOverlay(f),
        ],
      ),
    );
  }

  Widget _selectionOverlay(ChequeTemplateField f) {
    final s = _selectionSize(f);
    return Positioned(
      left: -4,
      top: -4,
      width: s.width + 8,
      height: s.height + 8,
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DashedBorderPainter(const Color(0xFF2563EB)),
              ),
            ),
            Positioned(
              left: 0,
              top: -18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  f.fieldName.label,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Approximate rendered size of a field, used for the selection box.
  Size _selectionSize(ChequeTemplateField f) {
    if (f.fieldType == ChequeTemplateFieldType.image) {
      return Size(f.imageWidth ?? 48, f.imageHeight ?? 48);
    }
    final hasLabel = f.fieldName != ChequeTemplateFieldName.bankName &&
        f.fieldName != ChequeTemplateFieldName.amountNumeric;
    final size = f.fontSize ?? 13;
    return Size(f.maxWidth ?? 260, size * (hasLabel ? 2.6 : 1.8) + 6);
  }

  Color _fieldColor(ChequeTemplateField f) {
    final hex = f.colorHex;
    if (hex != null && hex.isNotEmpty) {
      final cleaned = hex.replaceFirst('#', '');
      final v = int.tryParse(cleaned, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return const Color(0xFF1A1D26);
  }

  Widget _text(ChequeTemplateField f, String value) {
    final align = switch (f.alignment) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
    final weight = switch (f.fontWeight) {
      'w500' => FontWeight.w500,
      'w600' => FontWeight.w600,
      'w700' => FontWeight.w700,
      'bold' => FontWeight.bold,
      _ => FontWeight.normal,
    };
    return Text(
      value,
      textAlign: align,
      maxLines: f.maxWidth != null ? 3 : 1,
      overflow: f.maxWidth != null ? TextOverflow.ellipsis : TextOverflow.clip,
      style: TextStyle(
        fontSize: f.fontSize ?? 13,
        fontWeight: weight,
        color: _fieldColor(f),
        fontStyle: f.italic ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }

  Widget _bankLogo(ChequeTemplateField f) {
    final path = f.imagePath != null && f.imagePath!.isNotEmpty
        ? f.imagePath!
        : Constants.getBankLogoPath(bankKey);
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.account_balance_rounded,
            color: Color(0xFF2563EB)),
      ),
    );
  }

  /// The digital stamp is resolved dynamically from the cheque [status], never
  /// baked into the template: issued → blue, cleared → green, void → red,
  /// stale → amber. If the field points at a stamp image it is used instead.
  Widget _digitalStamp(ChequeTemplateField f) {
    if (f.imagePath != null && f.imagePath!.isNotEmpty) {
      return Image.asset(
        f.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _stampBox(f),
      );
    }
    return _stampBox(f);
  }

  Widget _stampBox(ChequeTemplateField f) {
    final (color, label) = switch (status) {
      'Cleared' => (const Color(0xFF10B981), 'CLEARED'),
      'Void' => (const Color(0xFFEF4444), 'VOID'),
      'Stale' => (const Color(0xFFF59E0B), 'STALE'),
      _ => (const Color(0xFF2563EB), 'DIGITAL STAMP'),
    };
    final size = f.imageWidth ?? 110.0;
    return Container(
      width: size,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(6),
        color: color.withValues(alpha: 0.08),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 14, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.1,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Classic crossed-cheque marking: two parallel diagonal lines, top-left.
  Widget _crossedMarking() {
    return Positioned(
      top: 0,
      left: 0,
      child: IgnorePointer(
        child: SizedBox(
          width: 130,
          height: 96,
          child: CustomPaint(
            painter: _CrossedLinesPainter(
              color: const Color(0xFF1A1D26).withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }

  static Uint8List _decodeDataUri(String uri) {
    final idx = uri.indexOf(',');
    final payload = idx != -1 ? uri.substring(idx + 1) : uri;
    return base64Decode(payload);
  }
}

class _CrossedLinesPainter extends CustomPainter {
  final Color color;

  _CrossedLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final start = Offset(10, size.height);
    final end = Offset(size.width - 6, 12);
    final dir = end - start;
    final length = dir.distance;
    if (length == 0) return;
    final perp = Offset(-dir.dy / length, dir.dx / length) * 16;

    canvas.drawLine(start, end, paint);
    canvas.drawLine(start + perp, end + perp, paint);
  }

  @override
  bool shouldRepaint(covariant _CrossedLinesPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Dashed blue border used to highlight the selected field in the editor.
class _DashedBorderPainter extends CustomPainter {
  final Color color;

  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    const dash = 5.0;
    const gap = 3.0;

    void dashLine(Offset a, Offset b) {
      final total = (b - a).distance;
      if (total == 0) return;
      final dir = (b - a) / total;
      var d = 0.0;
      while (d < total) {
        final end = math.min(d + dash, total);
        canvas.drawLine(a + dir * d, a + dir * end, paint);
        d = end + gap;
      }
    }

    final r = Offset.zero & size;
    dashLine(r.topLeft, r.topRight);
    dashLine(r.topRight, r.bottomRight);
    dashLine(r.bottomRight, r.bottomLeft);
    dashLine(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
