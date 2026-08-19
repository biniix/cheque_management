/// A database-driven bank cheque template.
///
/// Each bank (CBE, BOA, Awash, Dashen, …) has its own cheque leaf layout, so
/// instead of hardcoding designs we persist a template per bank. A template
/// stores the background image and the reference canvas size; the individual
/// positioned fields (date, payee, amount, …) live in [ChequeTemplateField]
/// and are linked back via [ChequeTemplateField.templateId].
///
/// Persisted through `LocalStore` (SharedPreferences), matching the rest of
/// the app's models.
class ChequeTemplate {
  final int id;
  final String bankKey;
  final String bankName;

  /// Display name of the template (e.g. "CBE 2025 Standard").
  final String templateName;

  /// Background image for the leaf. Either an asset path (e.g.
  /// `assets/banks/cbe.png`) or a `data:image/png;base64,…` URI when the admin
  /// uploaded a scan/photo of the real leaf.
  final String backgroundImagePath;

  /// Reference canvas size in logical pixels. The renderer draws fields at
  /// these coordinates and scales the whole thing to fit the screen, so
  /// positions stay accurate on every device. Defaults match a standard
  /// 8.5" x 3.5" cheque at ~96 dpi.
  final double canvasWidth;
  final double canvasHeight;

  final DateTime createdAt;

  ChequeTemplate({
    required this.id,
    required this.bankKey,
    required this.bankName,
    required this.templateName,
    this.backgroundImagePath = '',
    this.canvasWidth = 816,
    this.canvasHeight = 336,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasBackground => backgroundImagePath.isNotEmpty;

  /// True when the background is an uploaded image (data URI), false for
  /// asset paths.
  bool get backgroundIsDataUri => backgroundImagePath.startsWith('data:');

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank_key': bankKey,
        'bank_name': bankName,
        'template_name': templateName,
        'background_image_path': backgroundImagePath,
        'canvas_width': canvasWidth,
        'canvas_height': canvasHeight,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChequeTemplate.fromJson(Map<String, dynamic> json) => ChequeTemplate(
        id: json['id'] as int,
        bankKey: json['bank_key'] as String? ?? '',
        bankName: json['bank_name'] as String? ?? '',
        templateName: json['template_name'] as String? ?? '',
        backgroundImagePath: json['background_image_path'] as String? ?? '',
        canvasWidth: (json['canvas_width'] as num?)?.toDouble() ?? 816,
        canvasHeight: (json['canvas_height'] as num?)?.toDouble() ?? 336,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );

  ChequeTemplate copyWith({
    int? id,
    String? bankKey,
    String? bankName,
    String? templateName,
    String? backgroundImagePath,
    double? canvasWidth,
    double? canvasHeight,
    DateTime? createdAt,
  }) =>
      ChequeTemplate(
        id: id ?? this.id,
        bankKey: bankKey ?? this.bankKey,
        bankName: bankName ?? this.bankName,
        templateName: templateName ?? this.templateName,
        backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
        canvasWidth: canvasWidth ?? this.canvasWidth,
        canvasHeight: canvasHeight ?? this.canvasHeight,
        createdAt: createdAt ?? this.createdAt,
      );
}
