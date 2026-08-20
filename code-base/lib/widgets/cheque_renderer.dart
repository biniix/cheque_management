import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../models/cheque_template.dart';
import '../models/cheque_template_field.dart';

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
  final String chequeNumber;

  final bool isPreview;

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
    this.chequeNumber = '',
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

    if (path.isNotEmpty && template.backgroundIsDataUri) {
      return Positioned.fill(
        child: Image.memory(_decodeDataUri(path), fit: BoxFit.fill),
      );
    }

    return Positioned.fill(
      child: CustomPaint(
        painter: _ChequeBackgroundPainter(),
      ),
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
            'BIRR',
            amountInWords,
            isPreview: isPreview,
          ),
        ChequeTemplateFieldName.chequeNumber => _chequeLine(
            f,
            'CHEQUE NO',
            chequeNumber,
            isPreview: false,
          ),
      };
      final selectable = _selectable(f, child);
      return f.fieldType == ChequeTemplateFieldType.image
          ? _positionedImage(f, child: selectable)
          : _positioned(f, child: selectable);
    }).toList();
  }

  Widget _chequeLine(
    ChequeTemplateField f,
    String label,
    String value, {
    required bool isPreview,
    String? previewValue,
  }) {
    final effective = isPreview ? (previewValue ?? '') : value;
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

    final crossAxisAlignment = switch (f.alignment) {
      'center' => CrossAxisAlignment.center,
      'right' => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
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
            crossAxisAlignment: crossAxisAlignment,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.asset(
        path,
        width: f.imageWidth ?? 48,
        height: f.imageHeight ?? 48,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Container(
          width: f.imageWidth ?? 48,
          height: f.imageHeight ?? 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.account_balance_rounded,
              size: 24, color: Color(0xFF6B7280)),
        ),
      ),
    );
  }

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

class _ChequeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFEFEFE),
          const Color(0xFFF8F9FA),
          const Color(0xFFF5F6F8),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFE0E3E8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const inset = 8.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(inset, inset, w - inset * 2, h - inset * 2),
        const Radius.circular(2),
      ),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = const Color(0xFFB9BEC7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const cornerSize = 14.0;
    const cornerInset = 12.0;

    canvas.drawLine(
      Offset(cornerInset, cornerInset),
      Offset(cornerInset, cornerInset + cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cornerInset, cornerInset),
      Offset(cornerInset + cornerSize, cornerInset),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(w - cornerInset, cornerInset),
      Offset(w - cornerInset, cornerInset + cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(w - cornerInset, cornerInset),
      Offset(w - cornerInset - cornerSize, cornerInset),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(cornerInset, h - cornerInset),
      Offset(cornerInset, h - cornerInset - cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cornerInset, h - cornerInset),
      Offset(cornerInset + cornerSize, h - cornerInset),
      cornerPaint,
    );

    canvas.drawLine(
      Offset(w - cornerInset, h - cornerInset),
      Offset(w - cornerInset, h - cornerInset - cornerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(w - cornerInset, h - cornerInset),
      Offset(w - cornerInset - cornerSize, h - cornerInset),
      cornerPaint,
    );

    final watermarkPaint = Paint()
      ..color = const Color(0xFFF0F1F3)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    const spacing = 24.0;
    for (double x = -h; x < w + h; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + h, h),
        watermarkPaint,
      );
    }

    final accentPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(inset + 4, inset + 3),
      Offset(w - inset - 4, inset + 3),
      accentPaint,
    );

    final micrPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    const dotSpacing = 4.0;
    for (double x = inset + 20; x < w - inset - 20; x += dotSpacing * 2) {
      canvas.drawLine(
        Offset(x, h - inset - 6),
        Offset(x + dotSpacing, h - inset - 6),
        micrPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChequeBackgroundPainter oldDelegate) => false;
}
