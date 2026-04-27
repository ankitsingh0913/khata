import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:khata/core/api/api_client.dart';
import 'package:khata/models/bill.dart';

class BillApiService {
  static const String baseUrl = "http://10.0.2.2:8082/api/v1/bills";

  static Future<Bill?> getBillById(String id) async {
    try {
      final response = await ApiClient.dio.get('$baseUrl/$id');
      if (response.statusCode == 200) {
        return Bill.fromMap(response.data);
      }
    } catch (e) {
      print('Error loading bill: $e');
    }
    return null;
  }

  static Future<Bill?> createBill(Bill bill) async {
    try {
      // Map exactly what Spring Boot's BillCreateRequestDTO expects
      final requestData = {
        'customerId': bill.customerId,
        'items': bill.items
            .map((item) => {
                  'productId': item.productId,
                  // Make sure spelling matches BillItemRequestDTO in spring boot exactly!
                  'quantity': item.quantity,
                })
            .toList(),
        'discount': bill.discount,
        'tax': bill.tax ?? 0,
        'paymentType': bill.paymentType,
        'paidAmount': bill.paidAmount,
        'notes': bill.notes,
      };
      final response = await ApiClient.dio.post(
        baseUrl,
        data: requestData,
      );
      if (response.statusCode == 200) {
        return Bill.fromMap(response.data);
      }
    } catch (e) {
      print('Error creating bill: $e');
    }
    return null;
  }

  static Future<List<Bill>?> getAllBills() async {
    try {
      final response = await ApiClient.dio.get(baseUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Bill.fromMap(json)).toList();
      }
    } catch (e) {
      print('Error fetching all bills: $e');
    }
    return null;
  }

  // Step 4: Sync payment recording to the backend
  static Future<bool> recordPayment(Map<String, dynamic> paymentData) async {
    try {
      // Pointing to your payments endpoint
      final response = await ApiClient.dio.post(
        "http://10.0.2.2:8082/api/v1/payments",
        data: paymentData,
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error syncing payment to backend: $e');
      return false;
    }
  }
}
