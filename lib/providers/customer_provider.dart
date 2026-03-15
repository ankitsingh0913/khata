import 'package:flutter/foundation.dart';
import 'package:khata/models/customer.dart';
import 'package:khata/models/bill.dart';
import 'package:khata/services/api_services/customer_api_service.dart';

class CustomerProvider with ChangeNotifier {

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

  /*
  -----------------------------------------
  LOAD ALL CUSTOMERS
  -----------------------------------------
  */
  Future<void> loadCustomers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      _customers = await CustomerApiService.getCustomers();

      // customers who have pending dues
      _customersWithDues =
          _customers.where((c) => c.pendingAmount > 0).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /*
  -----------------------------------------
  SEARCH CUSTOMERS (CLIENT SIDE)
  -----------------------------------------
  */
  Future<void> searchCustomers(String query) async {

    if (query.isEmpty) {
      await loadCustomers();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final lower = query.toLowerCase();
      _customers = _customers
          .where((c) =>
      c.name.toLowerCase().contains(lower) ||
          c.phone.contains(query))
          .toList();

    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /*
  -----------------------------------------
  CREATE CUSTOMER
  -----------------------------------------
  */
  Future<Customer?> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    try {
      final body = {
        "name": name,
        "phone": phone,
        "email": email,
        "address": address,
      };

      final customer = await CustomerApiService.createCustomer(body);
      _customers.insert(0, customer);
      notifyListeners();
      return customer;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /*
  -----------------------------------------
  GET CUSTOMER DETAILS
  -----------------------------------------
  */
  Future<void> selectCustomer(String id) async {
    try {
      _isLoading = true;
      notifyListeners();
      _selectedCustomer = await CustomerApiService.getCustomerById(id);
      // Bills will be loaded later when we connect Bill APIs
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  /*
  -----------------------------------------
  DELETE CUSTOMER
  -----------------------------------------
  */
  Future<bool> deleteCustomer(String id) async {
    try {
      await CustomerApiService.deleteCustomer(id);
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

  /*
  -----------------------------------------
  CLEAR SELECTED CUSTOMER
  -----------------------------------------
  */
  void clearSelectedCustomer() {
    _selectedCustomer = null;
    _customerBills = [];
    notifyListeners();
  }

  /*
  -----------------------------------------
  TOTAL DUES
  -----------------------------------------
  */
  double get totalPendingAmount {
    return _customersWithDues.fold(
        0.0, (sum, c) => sum + c.pendingAmount);
  }
}