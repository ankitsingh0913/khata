class Payment {
  final String id;
  final String billId;
  final String? customerId;
  final double amount;
  final String paymentType;
  final String? notes;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.billId,
    this.customerId,
    required this.amount,
    required this.paymentType,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'customerId': customerId,
      'amount': amount,
      'paymentType': paymentType,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      billId: map['billId'],
      customerId: map['customerId'],
      amount: (map['amount'] ?? 0).toDouble(),
      paymentType: map['paymentType'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}