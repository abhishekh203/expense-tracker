class LendingPayment {
  final String id;
  final String lendingId;
  final double amount;
  final DateTime paymentDate;
  final String? accountId;
  final String? notes;
  final DateTime createdAt;

  LendingPayment({
    required this.id,
    required this.lendingId,
    required this.amount,
    required this.paymentDate,
    this.accountId,
    this.notes,
    required this.createdAt,
  });

  factory LendingPayment.fromJson(Map<String, dynamic> json) {
    return LendingPayment(
      id: json['id'] as String,
      lendingId: json['lending_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      accountId: json['account_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lending_id': lendingId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String().split('T')[0], // Date only
      'account_id': accountId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LendingPayment copyWith({
    String? id,
    String? lendingId,
    double? amount,
    DateTime? paymentDate,
    String? accountId,
    String? notes,
    DateTime? createdAt,
  }) {
    return LendingPayment(
      id: id ?? this.id,
      lendingId: lendingId ?? this.lendingId,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      accountId: accountId ?? this.accountId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'LendingPayment(id: $id, lendingId: $lendingId, amount: $amount, paymentDate: $paymentDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LendingPayment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
