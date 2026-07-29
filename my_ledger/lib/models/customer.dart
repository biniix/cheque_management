class Customer {
  final int id;
  final String name;
  final String bankName;
  final String bankKey;
  final String bankAccountNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.bankName,
    required this.bankKey,
    required this.bankAccountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bank_name': bankName,
        'bank_key': bankKey,
        'bank_account_number': bankAccountNumber,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as int,
        name: json['name'] as String,
        bankName: json['bank_name'] as String? ?? '',
        bankKey: json['bank_key'] as String? ?? '',
        bankAccountNumber: json['bank_account_number'] as String? ?? '',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );

  Customer copyWith({
    int? id,
    String? name,
    String? bankName,
    String? bankKey,
    String? bankAccountNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Customer(
        id: id ?? this.id,
        name: name ?? this.name,
        bankName: bankName ?? this.bankName,
        bankKey: bankKey ?? this.bankKey,
        bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
