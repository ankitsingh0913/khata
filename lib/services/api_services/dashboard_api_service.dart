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
    final responseData = response.data;

    if (responseData is! Map<String, dynamic>) {
      throw Exception(
        "Stats API returned unexpected response shape: ${responseData.runtimeType}",
      );
    }

    final statsData = responseData["data"];
    if (statsData == null) {
      throw Exception("Stats API returned invalid response");
    }

    if (statsData is! Map) {
      throw Exception(
        "Stats API returned unexpected data shape: ${statsData.runtimeType}",
      );
    }

    return Map<String, dynamic>.from(statsData);
  }
}
