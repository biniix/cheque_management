import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../constants.dart';
import '../models/cheque_template.dart';
import '../models/cheque_template_field.dart';

class ChequePdfGenerator {
  static const double pxToPt = 72 / 96;

  static const Map<String, String> _statusText = {
    'Cleared': 'CLEARED',
    'Void': 'VOID',
    'Stale': 'STALE',
  };

  Future<Uint8List> generate({
    required ChequeTemplate template,
    required List<ChequeTemplateField> fields,
    String bankKey = '',
    String bankName = '',
    String branch = '',
    required DateTime date,
    String payee = '',
    double amount = 0,
    String amountInWords = '',
    String status = 'Issued',
    bool crossed = false,
    String chequeNumber = '',
  }) async {
    final widthPt = template.canvasWidth * pxToPt;
    final heightPt = template.canvasHeight * pxToPt;

    final background = await _loadImage(template.backgroundImagePath);
    final bankLogo = await _loadImage(Constants.getBankLogoPath(bankKey));

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(widthPt, heightPt),
        margin: pw.EdgeInsets.zero,
        build: (_) {
          return pw.Stack(
            children: [
              pw.Positioned.fill(
                child: background != null
                    ? pw.Image(background, fit: pw.BoxFit.fill)
                    : pw.Container(color: PdfColors.white),
              ),
              if (crossed) _crossedMarking(),

              ...fields.map((f) => _buildField(
                    f,
                    template: template,
                    bankKey: bankKey,
                    bankName: bankName,
                    branch: branch,
                    date: date,
                    payee: payee,
                    amount: amount,
                    amountInWords: amountInWords,
                    status: status,
                    bankLogo: bankLogo,
                    chequeNumber: chequeNumber,
                  )),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildField(
    ChequeTemplateField f, {
    required ChequeTemplate template,
    required String bankKey,
    required String bankName,
    required String branch,
    required DateTime date,
    required String payee,
    required double amount,
    required String amountInWords,
    required String status,
    required pw.ImageProvider? bankLogo,
    String chequeNumber = '',
  }) {
    final left = f.x * pxToPt;
    final fieldH = f.fieldType == ChequeTemplateFieldType.image
        ? (f.imageHeight ?? 44)
        : 40.0;
    final top = (template.canvasHeight - f.y - fieldH) * pxToPt;

    switch (f.fieldName) {
      case ChequeTemplateFieldName.bankLogo:
        if (bankLogo == null) return pw.SizedBox.shrink();
        return pw.Positioned(
          left: left,
          top: top,
          child: pw.SizedBox(
            width: (f.imageWidth ?? 44) * pxToPt,
            height: (f.imageHeight ?? 44) * pxToPt,
            child: pw.Image(bankLogo, fit: pw.BoxFit.contain),
          ),
        );
      case ChequeTemplateFieldName.digitalStamp:
        return pw.Positioned(
          left: left,
          top: top,
          child: _digitalStamp(f, status),
        );
      case ChequeTemplateFieldName.bankName:
        return _positionedText(f, left, top, bankName);
      case ChequeTemplateFieldName.branch:
        return _positionedText(f, left, top, branch);
      case ChequeTemplateFieldName.date:
        return _positionedText(
            f, left, top, DateFormat('dd / MM / yyyy').format(date));
      case ChequeTemplateFieldName.payee:
        return _positionedText(f, left, top, payee);
      case ChequeTemplateFieldName.amountNumeric:
        return _positionedText(
          f,
          left,
          top,
          'ETB ${NumberFormat('#,##0.00', 'en_US').format(amount)}',
        );
      case ChequeTemplateFieldName.amountWords:
        return _pdfChequeLine(f, left, top, 'BIRR', amountInWords.isNotEmpty ? amountInWords : '___________________________');
      case ChequeTemplateFieldName.chequeNumber:
        return _pdfChequeLine(f, left, top, 'CHEQUE NO', chequeNumber.isNotEmpty ? chequeNumber : '000001');
    }
  }

  pw.Widget _positionedText(
    ChequeTemplateField f,
    double left,
    double top,
    String value,
  ) {
    final width = f.maxWidth != null ? f.maxWidth! * pxToPt : null;
    final child = pw.Text(
      value,
      maxLines: f.maxWidth != null ? 3 : 1,
      textAlign: switch (f.alignment) {
        'center' => pw.TextAlign.center,
        'right' => pw.TextAlign.right,
        _ => pw.TextAlign.left,
      },
      style: pw.TextStyle(
        fontSize: (f.fontSize ?? 13) * pxToPt,
        fontWeight: switch (f.fontWeight) {
          'w700' => pw.FontWeight.bold,
          'bold' => pw.FontWeight.bold,
          _ => pw.FontWeight.normal,
        },
        fontStyle: f.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
        color: _fieldColor(f),
      ),
    );

    return pw.Positioned(
      left: left,
      top: top,
      child: width != null ? pw.SizedBox(width: width, child: child) : child,
    );
  }

  pw.Widget _pdfChequeLine(
    ChequeTemplateField f,
    double left,
    double top,
    String label,
    String value,
  ) {
    final width = f.maxWidth != null ? f.maxWidth! * pxToPt : null;
    final fontSize = (f.fontSize ?? 13) * pxToPt;
    return pw.Positioned(
      left: left,
      top: top,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize * 0.62,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
              letterSpacing: 0.6,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.SizedBox(
            width: width,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                if (value.isNotEmpty)
                  pw.Text(
                    value,
                    textAlign: switch (f.alignment) {
                      'center' => pw.TextAlign.center,
                      'right' => pw.TextAlign.right,
                      _ => pw.TextAlign.left,
                    },
                    style: pw.TextStyle(
                      fontSize: fontSize,
                      fontWeight: switch (f.fontWeight) {
                        'w500' => pw.FontWeight.normal,
                        'w600' => pw.FontWeight.normal,
                        'w700' => pw.FontWeight.bold,
                        'bold' => pw.FontWeight.bold,
                        _ => pw.FontWeight.normal,
                      },
                      fontStyle: f.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
                      color: _fieldColor(f),
                    ),
                  ),
                pw.Container(
                  width: width,
                  height: 1,
                  color: PdfColors.grey400,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _digitalStamp(ChequeTemplateField f, String status) {
    final text = _statusText[status] ?? 'DIGITAL STAMP';
    final color = switch (status) {
      'Cleared' => PdfColors.green700,
      'Void' => PdfColors.red700,
      'Stale' => PdfColors.amber700,
      _ => PdfColors.blue700,
    };
    final width = (f.imageWidth ?? 110) * pxToPt;

    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1.4),
        borderRadius: pw.BorderRadius.circular(4),
        color: _blendWhite(color, 0.92),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Icon(const pw.IconData(0xe944), size: 12 * pxToPt, color: color),
          pw.SizedBox(height: 2),
          pw.Text(
            text,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 8 * pxToPt,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _crossedMarking() {
    return pw.Positioned(
      left: 0,
      top: 0,
      child: pw.CustomPaint(
        size: const PdfPoint(130 * pxToPt, 96 * pxToPt),
        painter: (canvas, size) {
          canvas
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(2.2 * pxToPt);
          const sx = 10 * pxToPt;
          final sy = size.y;
          final ex = size.x - 6 * pxToPt;
          const ey = 12 * pxToPt;
          final dx = ex - sx;
          final dy = ey - sy;
          final len = math.sqrt(dx * dx + dy * dy);
          if (len == 0) return;
          final px = (-dy / len) * (16 * pxToPt);
          final py = (dx / len) * (16 * pxToPt);
          canvas
            ..drawLine(sx, sy, ex, ey)
            ..drawLine(sx + px, sy + py, ex + px, ey + py);
        },
      ),
    );
  }

  PdfColor _fieldColor(ChequeTemplateField f) {
    final hex = f.colorHex;
    if (hex != null && hex.isNotEmpty) {
      final cleaned = hex.replaceFirst('#', '');
      final v = int.tryParse(cleaned, radix: 16);
      if (v != null) return PdfColor.fromInt(0xFF000000 | v);
    }
    return PdfColors.black;
  }

  Future<pw.ImageProvider?> _loadImage(String path) async {
    if (path.isEmpty) return null;
    try {
      Uint8List bytes;
      if (path.startsWith('data:')) {
        final idx = path.indexOf(',');
        final payload = idx != -1 ? path.substring(idx + 1) : path;
        bytes = base64Decode(payload);
      } else {
        final data = await rootBundle.load(path);
        bytes = data.buffer.asUint8List();
      }
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  static PdfColor _blendWhite(PdfColor color, double blend) {
    int mix(double c) => (c + (255 - c) * blend).round().clamp(0, 255).toInt();
    return PdfColor.fromInt(
      0xFF000000 |
          (mix(color.red) << 16) |
          (mix(color.green) << 8) |
          mix(color.blue),
    );
  }
}
