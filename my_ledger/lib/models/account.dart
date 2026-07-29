class Account {
  final int id;
  final String bankName;
  final String bankKey;
  final String accountName;
  final String accountNumber;
  final String? accountLast4;
  final double balance;
  final bool isVisible;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account({
    required this.id,
    required this.bankName,
    required this.bankKey,
    required this.accountName,
    required this.accountNumber,
    this.accountLast4,
    this.balance = 0.0,
    this.isVisible = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get last4 =>
      accountLast4 ?? (accountNumber.length >= 4 ? accountNumber.substring(accountNumber.length - 4) : accountNumber);

  Map<String, dynamic> toJson() => {
        'id': id,
        'bank_name': bankName,
        'bank_key': bankKey,
        'account_name': accountName,
        'account_number': accountNumber,
        'account_last4': accountLast4,
        'balance': balance,
        'is_visible': isVisible,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as int,
        bankName: json['bank_name'] as String,
        bankKey: json['bank_key'] as String? ?? '',
        accountName: json['account_name'] as String? ?? json['bank_name'] as String,
        accountNumber: json['account_number'] as String? ?? '',
        accountLast4: json['account_last4'] as String?,
        balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
        isVisible: json['is_visible'] == true || json['is_visible'] == 1,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );

  Account copyWith({
    int? id,
    String? bankName,
    String? bankKey,
    String? accountName,
    String? accountNumber,
    String? accountLast4,
    double? balance,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Account(
        id: id ?? this.id,
        bankName: bankName ?? this.bankName,
        bankKey: bankKey ?? this.bankKey,
        accountName: accountName ?? this.accountName,
        accountNumber: accountNumber ?? this.accountNumber,
        accountLast4: accountLast4 ?? this.accountLast4,
        balance: balance ?? this.balance,
        isVisible: isVisible ?? this.isVisible,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
