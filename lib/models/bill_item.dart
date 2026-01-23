class BillItem {
  final String id;
  final String billId;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double discount;

  BillItem({
    required this.id,
    required this.billId,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.discount = 0.0,
  });

  double get total => (price * quantity) - discount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billId': billId,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'discount': discount,
    };
  }

  factory BillItem.fromMap(Map<String, dynamic> map) {
    return BillItem(
      id: map['id'],
      billId: map['billId'],
      productId: map['productId'],
      productName: map['productName'],
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 1,
      discount: (map['discount'] ?? 0).toDouble(),
    );
  }

  BillItem copyWith({
    String? id,
    String? billId,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    double? discount,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}