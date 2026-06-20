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

    http.Response response;
    try {
      response = await http.post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // LOGIN
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {

    final url = Uri.parse("$baseUrl/login");

    http.Response response;
    try {
      response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // Google Login
  static Future<Map<String, dynamic>?> googleLogin(String idToken) async{
    final url = Uri.parse("$baseUrl/google");
    http.Response response;
    try {
      response = await http.post(
        url,
        headers:{"Content-Type": "application/json"},
        body:jsonEncode({"idToken":idToken}),
      ).timeout(const Duration(seconds:15));
    } catch(e){
      return null;
    }

    if(response.statusCode == 201 || response.statusCode == 200){
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch(_){
        return null;
      }
    }

    return null;
  }
}