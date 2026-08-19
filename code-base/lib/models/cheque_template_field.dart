/// The logical fields a bank cheque leaf contains. Each maps to the enum from
/// the spec so the renderer knows what value to draw at a field's position.
enum ChequeTemplateFieldName {
  bankLogo('bankLogo', 'Bank Logo', 'Fixed per template — the bank logo image.'),
  bankName('bankName', 'Bank Name', 'Bank name text (e.g. Commercial Bank of Ethiopia).'),
  branch('branch', 'Branch', 'Branch name / head-office line.'),
  date('date', 'Date', 'Cheque date (dd / MM / yyyy).'),
  payee('payee', 'Payee', 'Pay to the order of…'),
  amountNumeric('amountNumeric', 'Amount (figures)', 'Numeric amount, e.g. ETB 15,000.50.'),
  amountWords('amountWords', 'Amount (words)', 'Amount written out in words (wraps to maxWidth).'),
  digitalStamp('digitalStamp', 'Digital Stamp', 'Status-based stamp (issued / cleared / void).');

  const ChequeTemplateFieldName(this.key, this.label, this.description);

  final String key;
  final String label;
  final String description;

  static ChequeTemplateFieldName fromKey(String? key) =>
      values.firstWhere((e) => e.key == key, orElse: () => ChequeTemplateFieldName.payee);
}

/// How a field is drawn: rendered text or an image.
enum ChequeTemplateFieldType {
  text('text'),
  image('image');

  const ChequeTemplateFieldType(this.key);

  final String key;

  static ChequeTemplateFieldType fromKey(String? key) =>
      values.firstWhere((e) => e.key == key, orElse: () => ChequeTemplateFieldType.text);
}

/// One positioned element on a [ChequeTemplate].
///
/// `x` / `y` are offsets in canvas pixels measured from the top-left of the
/// background image. The same coordinates are used by the on-screen renderer
/// and the PDF generator so preview, print and MICR alignment all agree.
class ChequeTemplateField {
  final int id;

  /// FK to [ChequeTemplate.id].
  final int templateId;

  final ChequeTemplateFieldName fieldName;
  final ChequeTemplateFieldType fieldType;

  final double x;
  final double y;

  // ── Text-only options ──
  final double? fontSize;
  final String? fontWeight; // 'normal' | 'w500' | 'w600' | 'w700' | 'bold'
  final String? alignment; // 'left' | 'center' | 'right'
  final String? colorHex; // '#RRGGBB', null = default ink
  final bool italic;

  /// Constrains text width so long values (e.g. amountWords) wrap.
  final double? maxWidth;

  // ── Image-only options ──
  final String? imagePath;
  final double? imageWidth;
  final double? imageHeight;

  const ChequeTemplateField({
    required this.id,
    required this.templateId,
    required this.fieldName,
    required this.fieldType,
    required this.x,
    required this.y,
    this.fontSize,
    this.fontWeight,
    this.alignment,
    this.colorHex,
    this.italic = false,
    this.maxWidth,
    this.imagePath,
    this.imageWidth,
    this.imageHeight,
  });

  /// Convenience for text fields.
  factory ChequeTemplateField.text({
    required int id,
    required int templateId,
    required ChequeTemplateFieldName fieldName,
    required double x,
    required double y,
    double fontSize = 13,
    String fontWeight = 'normal',
    String alignment = 'left',
    double? maxWidth,
  }) =>
      ChequeTemplateField(
        id: id,
        templateId: templateId,
        fieldName: fieldName,
        fieldType: ChequeTemplateFieldType.text,
        x: x,
        y: y,
        fontSize: fontSize,
        fontWeight: fontWeight,
        alignment: alignment,
        maxWidth: maxWidth,
      );

  /// Convenience for image fields.
  factory ChequeTemplateField.image({
    required int id,
    required int templateId,
    required ChequeTemplateFieldName fieldName,
    required double x,
    required double y,
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
  }) =>
      ChequeTemplateField(
        id: id,
        templateId: templateId,
        fieldName: fieldName,
        fieldType: ChequeTemplateFieldType.image,
        x: x,
        y: y,
        imagePath: imagePath,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'template_id': templateId,
        'field_name': fieldName.key,
        'field_type': fieldType.key,
        'x': x,
        'y': y,
        'font_size': fontSize,
        'font_weight': fontWeight,
        'alignment': alignment,
        'color_hex': colorHex,
        'italic': italic,
        'max_width': maxWidth,
        'image_path': imagePath,
        'image_width': imageWidth,
        'image_height': imageHeight,
      };

  factory ChequeTemplateField.fromJson(Map<String, dynamic> json) =>
      ChequeTemplateField(
        id: json['id'] as int,
        templateId: json['template_id'] as int,
        fieldName: ChequeTemplateFieldName.fromKey(json['field_name'] as String?),
        fieldType: ChequeTemplateFieldType.fromKey(json['field_type'] as String?),
        x: (json['x'] as num?)?.toDouble() ?? 0,
        y: (json['y'] as num?)?.toDouble() ?? 0,
        fontSize: (json['font_size'] as num?)?.toDouble(),
        fontWeight: json['font_weight'] as String?,
        alignment: json['alignment'] as String?,
        colorHex: json['color_hex'] as String?,
        italic: json['italic'] as bool? ?? false,
        maxWidth: (json['max_width'] as num?)?.toDouble(),
        imagePath: json['image_path'] as String?,
        imageWidth: (json['image_width'] as num?)?.toDouble(),
        imageHeight: (json['image_height'] as num?)?.toDouble(),
      );

  ChequeTemplateField copyWith({
    int? id,
    int? templateId,
    ChequeTemplateFieldName? fieldName,
    ChequeTemplateFieldType? fieldType,
    double? x,
    double? y,
    double? fontSize,
    String? fontWeight,
    String? alignment,
    String? colorHex,
    bool? italic,
    double? maxWidth,
    String? imagePath,
    double? imageWidth,
    double? imageHeight,
  }) =>
      ChequeTemplateField(
        id: id ?? this.id,
        templateId: templateId ?? this.templateId,
        fieldName: fieldName ?? this.fieldName,
        fieldType: fieldType ?? this.fieldType,
        x: x ?? this.x,
        y: y ?? this.y,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        alignment: alignment ?? this.alignment,
        colorHex: colorHex ?? this.colorHex,
        italic: italic ?? this.italic,
        maxWidth: maxWidth ?? this.maxWidth,
        imagePath: imagePath ?? this.imagePath,
        imageWidth: imageWidth ?? this.imageWidth,
        imageHeight: imageHeight ?? this.imageHeight,
      );
}
