import 'package:khata/core/api/api_client.dart';
import 'package:khata/models/customer.dart';


class CustomerApiService {

  static Future<List<Customer>> getCustomers() async {

    final response = await ApiClient.dio.get("/customers");
    List data = response.data;

    return data.map((e) => Customer.fromJson(e)).toList();
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