import 'package:flutter/foundation.dart';
import 'package:khata/core/storage/token_storage.dart';
import 'package:khata/services/api_services/auth_api_service.dart';
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
      final accessToken = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();

      final prefs = await SharedPreferences.getInstance();

      if (accessToken != null && refreshToken != null) {
        _isLoggedIn = true;
        _shopName = prefs.getString('shopName');
        _ownerName = prefs.getString('ownerName');
        _phone = prefs.getString('phone');
      } else {
        _isLoggedIn = false;
      }

      _isInitialized = true;

      notifyListeners();
    } catch (e) {
      _isLoggedIn = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {

      final result = await AuthApiService.login(
        email: email,
        password: password,
      );

      if (result == null) return false;

      await TokenStorage.saveAccessToken(result["accessToken"]);
      await TokenStorage.saveRefreshToken(result["refreshToken"]);
      print(result);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);

      _isLoggedIn = true;

      notifyListeners();

      return true;

    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> signup({
    required String shopName,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {

      final result = await AuthApiService.signup(
        shopName: shopName,
        ownerName: ownerName,
        phone: phone,
        email: email,
        password: password,
      );

      if (result == null) return false;

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
      debugPrint("Signup error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await TokenStorage.clear();

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