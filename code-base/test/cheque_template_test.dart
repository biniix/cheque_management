import 'package:flutter_test/flutter_test.dart';
import 'package:cheque_management/models/cheque_template.dart';
import 'package:cheque_management/models/cheque_template_field.dart';
import 'package:cheque_management/utils/amount_to_words.dart';

void main() {
  group('amountToWords', () {
    test('whole birr amounts', () {
      expect(amountToWords(15000), 'Fifteen Thousand Birr');
      expect(amountToWords(18500), 'Eighteen Thousand Five Hundred Birr');
      expect(amountToWords(1), 'One Birr');
      expect(amountToWords(100), 'One Hundred Birr');
    });

    test('birr with cents', () {
      expect(
        amountToWords(15000.50),
        'Fifteen Thousand Birr and Fifty Cents',
      );
      expect(
        amountToWords(1.05),
        'One Birr and Five Cents',
      );
    });

    test('large amounts up to 999,999,999.99', () {
      expect(
        amountToWords(999999999.99),
        'Nine Hundred Ninety Nine Million Nine Hundred Ninety Nine Thousand '
        'Nine Hundred Ninety Nine Birr and Ninety Nine Cents',
      );
      expect(
        amountToWords(1000000),
        'One Million Birr',
      );
    });

    test('edge cases', () {
      expect(amountToWords(0), 'Zero Birr');
      expect(amountToWords(-5), 'Zero Birr');
    });
  });

  group('ChequeTemplate model', () {
    test('JSON round-trip', () {
      final template = ChequeTemplate(
        id: 7,
        bankKey: 'cbe',
        bankName: 'Commercial Bank of Ethiopia',
        templateName: 'CBE Standard',
        backgroundImagePath: 'assets/banks/cbe.png',
        canvasWidth: 816,
        canvasHeight: 336,
      );
      final restored = ChequeTemplate.fromJson(template.toJson());
      expect(restored.id, 7);
      expect(restored.bankKey, 'cbe');
      expect(restored.bankName, 'Commercial Bank of Ethiopia');
      expect(restored.templateName, 'CBE Standard');
      expect(restored.canvasWidth, 816);
      expect(restored.canvasHeight, 336);
      expect(restored.backgroundIsDataUri, isFalse);
    });

    test('data-uri background is detected', () {
      final template = ChequeTemplate(
        id: 1,
        bankKey: 'cbe',
        bankName: 'CBE',
        templateName: 't',
        backgroundImagePath: 'data:image/png;base64,AAAA',
      );
      expect(template.backgroundIsDataUri, isTrue);
    });
  });

  group('ChequeTemplateField model', () {
    test('text field JSON round-trip', () {
      final field = ChequeTemplateField.text(
        id: 3,
        templateId: 7,
        fieldName: ChequeTemplateFieldName.amountWords,
        x: 40,
        y: 156,
        fontSize: 14,
        fontWeight: 'w600',
        alignment: 'left',
        maxWidth: 420,
      );
      final restored = ChequeTemplateField.fromJson(field.toJson());
      expect(restored.fieldName, ChequeTemplateFieldName.amountWords);
      expect(restored.fieldType, ChequeTemplateFieldType.text);
      expect(restored.x, 40);
      expect(restored.y, 156);
      expect(restored.fontSize, 14);
      expect(restored.maxWidth, 420);
    });

    test('image field JSON round-trip', () {
      final field = ChequeTemplateField.image(
        id: 1,
        templateId: 7,
        fieldName: ChequeTemplateFieldName.bankLogo,
        x: 32,
        y: 26,
        imageWidth: 48,
        imageHeight: 48,
      );
      final restored = ChequeTemplateField.fromJson(field.toJson());
      expect(restored.fieldType, ChequeTemplateFieldType.image);
      expect(restored.imageWidth, 48);
      expect(restored.imageHeight, 48);
    });
  });
}
