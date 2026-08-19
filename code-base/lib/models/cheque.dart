class Cheque {
  final int id;
  final int chequebookId;
  final int? transactionId;
  final String chequeNumber;
  final DateTime date;
  final String payee;
  final double amount;
  final String amountInWords;
  final String bearerOrOrder; // 'bearer' or 'order'
  final bool crossed;
  final String status; // Issued, Cleared, Stale, Void
  final DateTime createdAt;
  final DateTime updatedAt;

  Cheque({
    required this.id,
    required this.chequebookId,
    this.transactionId,
    required this.chequeNumber,
    required this.date,
    required this.payee,
    required this.amount,
    required this.amountInWords,
    required this.bearerOrOrder,
    this.crossed = false,
    this.status = 'Issued',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  bool get isPostDated => date.isAfter(DateTime.now());
  bool get isStale =>
      DateTime.now().difference(date).inDays >= 180 && status != 'Void' && status != 'Cleared';

  Map<String, dynamic> toJson() => {
        'id': id,
        'chequebook_id': chequebookId,
        'transaction_id': transactionId,
        'cheque_number': chequeNumber,
        'date': date.toIso8601String(),
        'payee': payee,
        'amount': amount,
        'amount_in_words': amountInWords,
        'bearer_or_order': bearerOrOrder,
        'crossed': crossed,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory Cheque.fromJson(Map<String, dynamic> json) => Cheque(
        id: json['id'] as int,
        chequebookId: json['chequebook_id'] as int,
        transactionId: json['transaction_id'] as int?,
        chequeNumber: json['cheque_number'] as String,
        date: DateTime.parse(json['date'] as String),
        payee: json['payee'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        amountInWords: json['amount_in_words'] as String? ?? '',
        bearerOrOrder: json['bearer_or_order'] as String? ?? 'bearer',
        crossed: json['crossed'] as bool? ?? false,
        status: json['status'] as String? ?? 'Issued',
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      );

  Cheque copyWith({
    int? id,
    int? chequebookId,
    int? transactionId,
    String? chequeNumber,
    DateTime? date,
    String? payee,
    double? amount,
    String? amountInWords,
    String? bearerOrOrder,
    bool? crossed,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Cheque(
        id: id ?? this.id,
        chequebookId: chequebookId ?? this.chequebookId,
        transactionId: transactionId ?? this.transactionId,
        chequeNumber: chequeNumber ?? this.chequeNumber,
        date: date ?? this.date,
        payee: payee ?? this.payee,
        amount: amount ?? this.amount,
        amountInWords: amountInWords ?? this.amountInWords,
        bearerOrOrder: bearerOrOrder ?? this.bearerOrOrder,
        crossed: crossed ?? this.crossed,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );
}
