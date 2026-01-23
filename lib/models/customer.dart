class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final double totalPurchase;
  final double pendingAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.totalPurchase = 0.0,
    this.pendingAmount = 0.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'totalPurchase': totalPurchase,
      'pendingAmount': pendingAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      totalPurchase: (map['totalPurchase'] ?? 0).toDouble(),
      pendingAmount: (map['pendingAmount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalPurchase,
    double? pendingAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}