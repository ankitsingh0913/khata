import 'bill_item.dart';
import '../config/app_constants.dart';

class Bill {
  final String id;
  final String billNumber;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final List<BillItem> items;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paidAmount;
  final String paymentType;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Bill({
    required this.id,
    required this.billNumber,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.total,
    this.paidAmount = 0.0,
    required this.paymentType,
    required this.status,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  double get pendingAmount => total - paidAmount;
  bool get isPaid => status == AppConstants.billPaid;
  bool get isCredit => paymentType == AppConstants.paymentCredit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'paidAmount': paidAmount,
      'paymentType': paymentType,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map, {List<BillItem>? items}) {
    return Bill(
      id: map['id'],
      billNumber: map['billNumber'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      items: items ?? [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      paymentType: map['paymentType'] ?? AppConstants.paymentCash,
      status: map['status'] ?? AppConstants.billUnpaid,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Bill copyWith({
    String? id,
    String? billNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<BillItem>? items,
    double? subtotal,
    double? discount,
    double? tax,
    double? total,
    double? paidAmount,
    String? paymentType,
    String? status,
    String? notes,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentType: paymentType ?? this.paymentType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}