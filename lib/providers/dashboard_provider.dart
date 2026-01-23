import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../models/bill.dart';
import '../services/database_service.dart';

class DashboardProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _salesChartData = [];
  List<Customer> _topCustomers = [];
  List<Bill> _recentBills = [];
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get salesChartData => _salesChartData;
  List<Customer> get topCustomers => _topCustomers;
  List<Bill> get recentBills => _recentBills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get todaySales => (_stats['todaySales'] ?? 0).toDouble();
  int get todayBillCount => _stats['todayBillCount'] ?? 0;
  double get monthlySales => (_stats['monthlySales'] ?? 0).toDouble();
  int get monthlyBillCount => _stats['monthlyBillCount'] ?? 0;
  double get totalPending => (_stats['totalPending'] ?? 0).toDouble();
  int get customerCount => _stats['customerCount'] ?? 0;
  int get productCount => _stats['productCount'] ?? 0;
  int get lowStockCount => _stats['lowStockCount'] ?? 0;

  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _stats = await _db.getDashboardStats();
      _salesChartData = await _db.getSalesChart(days: 7);

      final topCustomersData = await _db.getTopCustomers(limit: 5);
      _topCustomers = topCustomersData.map((map) => Customer.fromMap(map)).toList();

      _recentBills = (await _db.getAllBills(limit: 5)).cast<Bill>();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshStats() async {
    try {
      _stats = await _db.getDashboardStats();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }
}