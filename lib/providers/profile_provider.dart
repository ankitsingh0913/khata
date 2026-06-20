import 'package:flutter/foundation.dart';
import 'package:khata/services/api_services/profile_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider with ChangeNotifier {
  String? _shopName;
  String? _fullName;
  String? _phone;
  String? _email;
  String? _address;
  String? _gstNumber;
  String? _upiId;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  String? get shopName => _shopName;
  String? get fullName => _fullName;
  String? get phone => _phone;
  String? get email => _email;
  String? get address => _address;
  String? get gstNumber => _gstNumber;
  String? get upiId => _upiId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get error => _error;

  /// Load profile — first from local prefs, then try the remote API
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _shopName = prefs.getString('shopName');
      _fullName = prefs.getString('fullName');
      _phone = prefs.getString('phone');
      _email = prefs.getString('email');
      _address = prefs.getString('address');
      _gstNumber = prefs.getString('gstNumber');
      _upiId = prefs.getString('upiId');

      // Try to refresh from API
      final remote = await ProfileApiService.getProfile();
      if (remote != null) {
        _shopName = remote['shopName'] ?? _shopName;
        _fullName = remote['fullName'] ?? _fullName;
        _phone = remote['phone'] ?? _phone;
        _email = remote['email'] ?? _email;
        _address = remote['address'] ?? _address;
        _gstNumber = remote['gstNumber'] ?? _gstNumber;
        _upiId = remote['upiId'] ?? _upiId;

        // Persist back
        await _persistLocally();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('ProfileProvider.loadProfile error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String shopName,
    required String fullName,
    required String phone,
    String? email,
    String? address,
    String? gstNumber,
    String? upiId,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    bool success = false;

    try {
      success = await ProfileApiService.updateProfile(
        shopName: shopName,
        fullName: fullName,
        phone: phone,
        email: email,
        address: address,
        gstNumber: gstNumber,
        upiId: upiId,
      );

      if (success) {
        _shopName = shopName;
        _fullName = fullName;
        _phone = phone;
        _email = email;
        _address = address;
        _gstNumber = gstNumber;
        _upiId = upiId;

        await _persistLocally();
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('ProfileProvider.updateProfile error: $e');
    }

    _isSaving = false;
    notifyListeners();
    return success;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    bool success = false;
    try {
      success = await ProfileApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isSaving = false;
    notifyListeners();
    return success;
  }

  Future<void> _persistLocally() async {
    final prefs = await SharedPreferences.getInstance();
    if (_shopName != null) { await prefs.setString('shopName', _shopName!); } else { await prefs.remove('shopName'); }
    if (_fullName != null) { await prefs.setString('fullName', _fullName!); } else { await prefs.remove('fullName'); }
    if (_phone != null) { await prefs.setString('phone', _phone!); } else { await prefs.remove('phone'); }
    if (_email != null) { await prefs.setString('email', _email!); } else { await prefs.remove('email'); }
    if (_address != null) { await prefs.setString('address', _address!); } else { await prefs.remove('address'); }
    if (_gstNumber != null) { await prefs.setString('gstNumber', _gstNumber!); } else { await prefs.remove('gstNumber'); }
    if (_upiId != null) { await prefs.setString('upiId', _upiId!); } else { await prefs.remove('upiId'); }
  }
}
