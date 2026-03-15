import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {

  static const String baseUrl = "http://10.0.2.2:8082/api/v1/auth";

  // SIGNUP
  static Future<Map<String, dynamic>?> signup({
    required String shopName,
    required String ownerName,
    required String phone,
    required String email,
    required String password,
  }) async {

    final url = Uri.parse("$baseUrl/signup");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "shopName": shopName,
        "fullName": ownerName,
        "phone": phone,
        "email": email,
        "password": password
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  // LOGIN
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {

    final url = Uri.parse("$baseUrl/login");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }
}