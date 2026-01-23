import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/bill.dart';
import '../models/bill_item.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../models/payment.dart';
import '../config/app_constants.dart';
import '../services/database_service.dart';

class BillProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Bill> _bills = [];
  List<Bill> _unpaidBills = [];
  Bill? _currentBill;
  List<BillItem> _cartItems = [];
  Customer? _selectedCustomer;
  String _paymentType = AppConstants.paymentCash;
  double _discount = 0.0;
  bool _isLoading = false;
  String? _error;

  List<Bill> get bills => _bills;
  List<Bill> get unpaidBills => _unpaidBills;
  Bill? get currentBill => _currentBill;
  List<BillItem> get cartItems => _cartItems;
  Customer? get selectedCustomer => _selectedCustomer;
  String get paymentType => _paymentType;
  double get discount => _discount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get subtotal => _cartItems.fold(0.0, (sum, item) => sum + item.total);
  double get total => subtotal - _discount;
  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  Future<void> loadBills({int? limit}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _bills = await _db.getAllBills(limit: limit);
      _unpaidBills = await _db.getUnpaidBills();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBillsByCustomer(String customerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _bills = await _db.getBillsByCustomer(customerId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1}) {
    final existingIndex = _cartItems.indexWhere((item) => item.productId == product.id);

    if (existingIndex != -1) {
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      _cartItems.add(BillItem(
        id: const Uuid().v4(),
        billId: '',
        productId: product.id,
        productName: product.name,
        price: product.sellingPrice,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  void updateCartItemQuantity(String productId, int quantity) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.productId == productId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _selectedCustomer = null;
    _paymentType = AppConstants.paymentCash;
    _discount = 0.0;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setPaymentType(String type) {
    _paymentType = type;
    notifyListeners();
  }

  void setDiscount(double discount) {
    _discount = discount;
    notifyListeners();
  }

  Future<Bill?> createBill({String? notes}) async {
    if (_cartItems.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final billNumber = await _db.generateBillNumber();
      final billId = const Uuid().v4();

      final items = _cartItems.map((item) => item.copyWith(billId: billId)).toList();

      String status;
      double paidAmount;

      if (_paymentType == AppConstants.paymentCredit) {
        status = AppConstants.billUnpaid;
        paidAmount = 0;
      } else {
        status = AppConstants.billPaid;
        paidAmount = total;
      }

      final bill = Bill(
        id: billId,
        billNumber: billNumber,
        customerId: _selectedCustomer?.id,
        customerName: _selectedCustomer?.name,
        customerPhone: _selectedCustomer?.phone,
        items: items,
        subtotal: subtotal,
        discount: _discount,
        total: total,
        paidAmount: paidAmount,
        paymentType: _paymentType,
        status: status,
        notes: notes,
      );

      await _db.insertBill(bill);
      _currentBill = bill;
      _bills.insert(0, bill);

      if (_paymentType == AppConstants.paymentCredit) {
        _unpaidBills.insert(0, bill);
      }

      clearCart();

      _isLoading = false;
      notifyListeners();
      return bill;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> recordPayment({
    required String billId,
    required double amount,
    required String paymentType,
    String? notes,
  }) async {
    try {
      final payment = Payment(
        id: const Uuid().v4(),
        billId: billId,
        customerId: _currentBill?.customerId,
        amount: amount,
        paymentType: paymentType,
        notes: notes,
      );

      await _db.insertPayment(payment);
      await loadBills();

      // Update current bill if it's the same
      if (_currentBill?.id == billId) {
        _currentBill = await _db.getBillById(billId);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Bill?> getBillById(String id) async {
    try {
      final bill = await _db.getBillById(id);
      _currentBill = bill;
      notifyListeners();
      return bill;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Payment>> getPaymentsForBill(String billId) async {
    try {
      return await _db.getPaymentsByBill(billId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
}