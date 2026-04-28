import 'package:khata/core/api/api_client.dart';
import 'package:khata/models/customer.dart';

class CustomerApiService {
  static Map<String, dynamic> _extractCustomerPayload(dynamic responseData) {
    final responseMap = Map<String, dynamic>.from(responseData as Map);
    final payload = responseMap['data'] ?? responseMap;

    return Map<String, dynamic>.from(payload as Map);
  }

  static Future<List<Customer>> getCustomers() async {
    final response = await ApiClient.dio.get("/customers");

    if (response.statusCode != 200 || response.data == null) {
      throw Exception("Failed to fetch customers: ${response.statusCode}");
    }

    final responseData = response.data;
    final data = responseData is List
        ? responseData
        : responseData is Map
            ? (responseData['data'] is List
                ? responseData['data'] as List
                : responseData['items'] is List
                    ? responseData['items'] as List
                    : const [])
            : const [];

    return data
        .map((e) => Customer.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static Future<Customer> createCustomer(Map<String, dynamic> body) async {
    final response = await ApiClient.dio.post(
      "/customers",
      data: body,
    );

    return Customer.fromJson(_extractCustomerPayload(response.data));
  }

  static Future<Customer> getCustomerById(String id) async {
    final response = await ApiClient.dio.get("/customers/$id");

    return Customer.fromJson(_extractCustomerPayload(response.data));
  }

  static Future<void> deleteCustomer(String id) async {
    await ApiClient.dio.delete("/customers/$id");
  }
}
