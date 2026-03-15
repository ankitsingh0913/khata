import 'package:khata/core/api/api_client.dart';
import 'package:khata/models/product.dart';

class ProductApiService {

  static Future<List<Product>> getProducts() async {
    final response = await ApiClient.dio.get("/products");
    print("PRODUCT API RESPONSE: ${response.data}");

    final responseData = response.data;
    if (responseData is List) {
      return responseData.map((e) => Product.fromJson(e)).toList();
    }
    if (responseData["data"] != null) {
      return (responseData["data"] as List)
          .map((e) => Product.fromJson(e))
          .toList();
    }

    return [];
  }

  static Future<Product> getProductById(String id) async {
    final response = await ApiClient.dio.get("/products/$id");

    return Product.fromJson(response.data["data"]);
  }

  static Future<Product> createProduct(Map<String, dynamic> payload) async {
    final response = await ApiClient.dio.post(
      "/products",
      data: payload,
    );

    return Product.fromJson(response.data["data"]);
  }

  static Future<Product> updateProduct(
      String id, Map<String, dynamic> payload) async {

    final response = await ApiClient.dio.put(
      "/products/$id",
      data: payload,
    );

    return Product.fromJson(response.data["data"]);
  }

  static Future<void> deleteProduct(String id) async {
    await ApiClient.dio.delete("/products/$id");
  }

  static Future<void> updateStock(
      String productId, int quantity, bool isDeduct) async {

    await ApiClient.dio.post(
      "/products/$productId/stock",
      data: {
        "quantity": quantity,
        "isDeduct": isDeduct,
      },
    );
  }
}