class Transaction {
  final int id;
  final int accountId;
  final String type; // deposit, transfer, cheque_issued, cheque_received
  final double amount;
  final DateTime date;
  final String? payee;
  final String? description;
  final String? referenceNo;
  final int? customerId;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    this.payee,
    this.description,
    this.referenceNo,
    this.customerId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isCredit => amount > 0;
  bool get isDebit => amount < 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'account_id': accountId,
        'type': type,
        'amount': amount,
        'date': date.toIso8601String(),
        'payee': payee,
        'description': description,
        'reference_no': referenceNo,
        'customer_id': customerId,
        'created_at': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as int,
        accountId: json['account_id'] as int,
        type: json['type'] as String,
        amount: _parseDouble(json['amount']),
        date: DateTime.parse(json['date'] as String),
        payee: json['payee'] as String?,
        description: json['description'] as String?,
        referenceNo: json['reference_no'] as String?,
        customerId: json['customer_id'] as int?,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      );

  /// Handle both num and String types from JSON (MySQL DECIMAL comes as String)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
