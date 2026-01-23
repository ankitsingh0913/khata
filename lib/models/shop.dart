class Shop {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String? email;
  final String? address;
  final String? gstNumber;
  final String? logo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Shop({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.phone,
    this.email,
    this.address,
    this.gstNumber,
    this.logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'phone': phone,
      'email': email,
      'address': address,
      'gstNumber': gstNumber,
      'logo': logo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'],
      name: map['name'],
      ownerName: map['ownerName'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      gstNumber: map['gstNumber'],
      logo: map['logo'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Shop copyWith({
    String? id,
    String? name,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
    String? logo,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerName: ownerName ?? this.ownerName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      logo: logo ?? this.logo,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Shop(id: $id, name: $name, ownerName: $ownerName, phone: $phone)';
  }
}