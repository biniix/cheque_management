class ChequeBook {
  final int id;
  final int accountId;
  final int size;
  final String startNumber;
  final String endNumber;

  /// The cheque template chosen when this book was created. When set, the
  /// write-cheque flow renders exactly this template; otherwise it falls back
  /// to the bank's template.
  final int? templateId;

  final DateTime createdAt;

  ChequeBook({
    required this.id,
    required this.accountId,
    required this.size,
    required this.startNumber,
    required this.endNumber,
    this.templateId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'size': size,
        'start_number': startNumber,
        'end_number': endNumber,
        'template_id': templateId,
        'created_at': createdAt.toIso8601String(),
      };

  factory ChequeBook.fromJson(Map<String, dynamic> json) => ChequeBook(
        id: json['id'] as int,
        accountId: json['account_id'] as int,
        size: json['size'] as int,
        startNumber: json['start_number'] as String,
        endNumber: json['end_number'] as String,
        templateId: json['template_id'] as int?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );
}
