
import 'package:khata/core/api/api_client.dart';

class DashboardApiService {

  static Future<Map<String, dynamic>> getDashboard() async {

    final response = await ApiClient.dio.get("/dashboard");

    print("FULL RESPONSE -> ${response.data}");

    if (response.data == null) {
      throw Exception("Dashboard API returned null");
    }

    if (response.data is Map<String, dynamic>) {
      if (response.data["data"] != null) {
        return Map<String, dynamic>.from(response.data["data"]);
      }
      return response.data as Map<String, dynamic>;
    }

    throw Exception("Invalid dashboard response format");
  }

  static Future<Map<String, dynamic>> getStats() async {

    final response = await ApiClient.dio.get("/dashboard/stats");

    return response.data["data"];

  }
}