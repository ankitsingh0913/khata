import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../services/database_service.dart';

class CustomerProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<Customer> _customers = [];
  List<Customer> _customersWithDues = [];
  Customer? _selectedCustomer;
  List<Bill> _customerBills = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  List<Customer> get customersWithDues => _customersWithDues;
  Customer? get selectedCustomer => _selectedCustomer;
  List<Bill> get customerBills => _customerBills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _db.getAllCustomers();
      _customersWithDues = await _db.getCustomersWithPendingAmount();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchCustomers(String query) async {
    if (query.isEmpty) {
      await loadCustomers();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _customers = await _db.searchCustomers(query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Customer?> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      final customer = Customer(
        id: const Uuid().v4(),
        name: name,
        phone: phone,
        email: email,
        address: address,
      );

      await _db.insertCustomer(customer);
      _customers.insert(0, customer);
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _db.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == customer.id);
      if (index != -1) {
        _customers[index] = customer;
      }
      if (_selectedCustomer?.id == customer.id) {
        _selectedCustomer = customer;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      await _db.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      if (_selectedCustomer?.id == id) {
        _selectedCustomer = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> selectCustomer(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      _selectedCustomer = await _db.getCustomerById(id);
      if (_selectedCustomer != null) {
        _customerBills = await _db.getBillsByCustomer(id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearSelectedCustomer() {
    _selectedCustomer = null;
    _customerBills = [];
    notifyListeners();
  }

  double get totalPendingAmount {
    return _customersWithDues.fold(0.0, (sum, c) => sum + c.pendingAmount);
  }
}