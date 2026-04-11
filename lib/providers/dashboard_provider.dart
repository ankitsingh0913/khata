import 'package:flutter/foundation.dart';
import 'package:khata/services/api_services/dashboard_api_service.dart';
import '../models/customer.dart';
import '../models/bill.dart';

class DashboardProvider with ChangeNotifier {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _salesChartData = [];
  List<Customer> _topCustomers = [];
  List<Bill> _recentBills = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  Map<String, dynamic> get stats => _stats;
  List<Map<String, dynamic>> get salesChartData => _salesChartData;
  List<Customer> get topCustomers => _topCustomers;
  List<Bill> get recentBills => _recentBills;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
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
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await DashboardApiService.getDashboard();
      _stats = data["stats"] ?? {};
      _salesChartData =
          List<Map<String, dynamic>>.from(data["salesChart"] ?? []);
      _topCustomers = (data["topCustomers"] as List? ?? [])
          .map((e) => Customer.fromJson(e))
          .toList();

      _recentBills = (data["recentBills"] as List? ?? [])
          .map((e) => Bill.fromJson(e))
          .toList();

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint("DashboardProvider error: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshStats() async {
    try {
      final stats = await DashboardApiService.getStats();
      _stats = stats;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      debugPrint("DashboardProvider refresh error: $e");
      notifyListeners();
    }
  }
}
