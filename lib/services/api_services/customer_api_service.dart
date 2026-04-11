import 'package:khata/core/api/api_client.dart';
import 'package:khata/models/customer.dart';

class CustomerApiService {
  static Future<List<Customer>> getCustomers() async {
    final response = await ApiClient.dio.get("/customers");

    if (response.statusCode != 200 || response.data == null) {
      throw Exception("Failed to fetch customers: ${response.statusCode}");
    }

    final data = response.data as List? ?? [];
    return data
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<Customer> createCustomer(Map<String, dynamic> body) async {
    final response = await ApiClient.dio.post(
      "/customers",
      data: body,
    );

    return Customer.fromJson(response.data);
  }

  static Future<Customer> getCustomerById(String id) async {
    final response = await ApiClient.dio.get("/customers/$id");

    return Customer.fromJson(response.data);
  }

  static Future<void> deleteCustomer(String id) async {
    await ApiClient.dio.delete("/customers/$id");
  }
}
