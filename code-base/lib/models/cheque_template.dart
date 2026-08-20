

class ChequeTemplate {
  final int id;
  final String bankKey;
  final String bankName;

  final String templateName;

  final String backgroundImagePath;

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
