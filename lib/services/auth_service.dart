import 'package:shared_preferences/shared_preferences.dart';
import '../models/shop.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyShopId = 'shopId';
  static const String _keyShopName = 'shopName';
  static const String _keyOwnerName = 'ownerName';
  static const String _keyPhone = 'phone';
  static const String _keyEmail = 'email';
  static const String _keyAddress = 'address';
  static const String _keyGstNumber = 'gstNumber';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final preferences = await prefs;
    return preferences.getBool(_keyIsLoggedIn) ?? false;
  }

  // Get current shop details
  Future<Shop?> getCurrentShop() async {
    final preferences = await prefs;
    final isLogged = preferences.getBool(_keyIsLoggedIn) ?? false;

    if (!isLogged) return null;

    final shopId = preferences.getString(_keyShopId);
    final shopName = preferences.getString(_keyShopName);
    final ownerName = preferences.getString(_keyOwnerName);
    final phone = preferences.getString(_keyPhone);

    if (shopId == null || shopName == null || ownerName == null || phone == null) {
      return null;
    }

    return Shop(
      id: shopId,
      name: shopName,
      ownerName: ownerName,
      phone: phone,
      email: preferences.getString(_keyEmail),
      address: preferences.getString(_keyAddress),
      gstNumber: preferences.getString(_keyGstNumber),
    );
  }

  // Login / Register shop
  Future<bool> login({
    required String shopId,
    required String shopName,
    required String ownerName,
    required String phone,
    String? email,
    String? address,
    String? gstNumber,
  }) async {
    try {
      final preferences = await prefs;

      await preferences.setBool(_keyIsLoggedIn, true);
      await preferences.setString(_keyShopId, shopId);
      await preferences.setString(_keyShopName, shopName);
      await preferences.setString(_keyOwnerName, ownerName);
      await preferences.setString(_keyPhone, phone);

      if (email != null) {
        await preferences.setString(_keyEmail, email);
      }
      if (address != null) {
        await preferences.setString(_keyAddress, address);
      }
      if (gstNumber != null) {
        await preferences.setString(_keyGstNumber, gstNumber);
      }

      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  // Update shop details
  Future<bool> updateShopDetails({
    String? shopName,
    String? ownerName,
    String? phone,
    String? email,
    String? address,
    String? gstNumber,
  }) async {
    try {
      final preferences = await prefs;

      if (shopName != null) {
        await preferences.setString(_keyShopName, shopName);
      }
      if (ownerName != null) {
        await preferences.setString(_keyOwnerName, ownerName);
      }
      if (phone != null) {
        await preferences.setString(_keyPhone, phone);
      }
      if (email != null) {
        await preferences.setString(_keyEmail, email);
      }
      if (address != null) {
        await preferences.setString(_keyAddress, address);
      }
      if (gstNumber != null) {
        await preferences.setString(_keyGstNumber, gstNumber);
      }

      return true;
    } catch (e) {
      print('Update error: $e');
      return false;
    }
  }

  // Logout
  Future<bool> logout() async {
    try {
      final preferences = await prefs;
      await preferences.clear();
      return true;
    } catch (e) {
      print('Logout error: $e');
      return false;
    }
  }

  // Verify OTP (mock implementation - replace with real OTP service)
  Future<bool> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    // Mock OTP verification
    // In production, integrate with SMS gateway like Firebase Auth, MSG91, etc.
    await Future.delayed(const Duration(seconds: 1));

    // For demo, accept any 6-digit OTP or "123456"
    if (otp.length == 6 || otp == "123456") {
      return true;
    }
    return false;
  }

  // Send OTP (mock implementation)
  Future<bool> sendOtp({required String phone}) async {
    // Mock OTP sending
    // In production, integrate with SMS gateway
    await Future.delayed(const Duration(seconds: 1));

    print('OTP sent to $phone');
    return true;
  }

  // Get stored phone number
  Future<String?> getPhone() async {
    final preferences = await prefs;
    return preferences.getString(_keyPhone);
  }

  // Get stored shop name
  Future<String?> getShopName() async {
    final preferences = await prefs;
    return preferences.getString(_keyShopName);
  }

  // Get stored owner name
  Future<String?> getOwnerName() async {
    final preferences = await prefs;
    return preferences.getString(_keyOwnerName);
  }
}