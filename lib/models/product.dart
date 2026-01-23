class Product {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final String? barcode;
  final double purchasePrice;
  final double sellingPrice;
  final int stock;
  final int lowStockAlert;
  final String unit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.barcode,
    required this.purchasePrice,
    required this.sellingPrice,
    this.stock = 0,
    this.lowStockAlert = 10,
    this.unit = 'pcs',
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get profit => sellingPrice - purchasePrice;
  double get profitPercentage => purchasePrice > 0
      ? ((sellingPrice - purchasePrice) / purchasePrice) * 100
      : 0;
  bool get isLowStock => stock <= lowStockAlert;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'barcode': barcode,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'stock': stock,
      'lowStockAlert': lowStockAlert,
      'unit': unit,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      barcode: map['barcode'],
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      stock: map['stock'] ?? 0,
      lowStockAlert: map['lowStockAlert'] ?? 10,
      unit: map['unit'] ?? 'pcs',
      isActive: map['isActive'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    int? stock,
    int? lowStockAlert,
    String? unit,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stock: stock ?? this.stock,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}