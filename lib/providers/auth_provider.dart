import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoggedIn = false;
  String? _shopName;
  String? _ownerName;
  String? _phone;
  bool _isInitialized = false;


  bool get isLoggedIn => _isLoggedIn;
  String? get shopName => _shopName;
  String? get ownerName => _ownerName;
  String? get phone => _phone;
  bool get isInitialized => _isInitialized;


  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _shopName = prefs.getString('shopName');
      _ownerName = prefs.getString('ownerName');
      _phone = prefs.getString('phone');
      _isInitialized = true;

      debugPrint('AuthProvider: checkLoginStatus completed, isLoggedIn=$_isLoggedIn');

      // Direct notify - this is called from async context, safe to use
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider error: $e');
      _isLoggedIn = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String phone,
    required String shopName,
    required String ownerName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('shopName', shopName);
      await prefs.setString('ownerName', ownerName);
      await prefs.setString('phone', phone);

      _isLoggedIn = true;
      _shopName = shopName;
      _ownerName = ownerName;
      _phone = phone;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      _isLoggedIn = false;
      _shopName = null;
      _ownerName = null;
      _phone = null;

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider logout error: $e');
    }
  }


  Future<void> updateShopInfo({String? shopName, String? ownerName}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (shopName != null) {
        await prefs.setString('shopName', shopName);
        _shopName = shopName;
      }
      if (ownerName != null) {
        await prefs.setString('ownerName', ownerName);
        _ownerName = ownerName;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider updateShopInfo error: $e');
    }
  }
}