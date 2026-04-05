import 'dart:convert';
import 'package:khata/core/api/api_client.dart';

class ProfileApiService {
  static const String _baseUrl = "http://10.0.2.2:8082/api/v1";

  static Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await ApiClient.dio.get('$_baseUrl/users/me');
      if (response.statusCode == 200) {
        print("PROFILE DATA: ${response.data}");
        return response.data;
      }
    } catch (e) {
      // Return null on error — caller will handle gracefully
    } finally {
      
    }
    return null;
  }

  static Future<bool> updateProfile({
    required String shopName,
    required String fullName,
    required String phone,
    String? email,
    String? address,
    String? gstNumber,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '$_baseUrl/users/',
        data: jsonEncode({
          'shopName': shopName,
          'fullName': fullName,
          'phone': phone,
          if (email != null) 'email': email,
          if (address != null) 'address': address,
          if (gstNumber != null) 'gstNumber': gstNumber,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.dio.put(
        '$_baseUrl/auth/change-password',
        data: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
