import 'package:khata/core/api/api_client.dart';
import 'package:khata/models/product.dart';

class ProductApiService {
  static List<Product> _parseProductList(
      dynamic payload, String operation, dynamic responseData) {
    if (payload is! List) {
      throw FormatException(
        'Invalid product payload for $operation: expected a List, got ${payload.runtimeType}. Response: $responseData',
      );
    }

    try {
      return payload
          .map(
              (product) => Product.fromJson(Map<String, dynamic>.from(product)))
          .toList();
    } on TypeError catch (error) {
      throw FormatException(
        'Invalid product payload for $operation: list items must be map-shaped product objects. Error: $error. Response: $responseData',
      );
    }
  }

  static Product _parseSingleProductResponse(
      dynamic responseData, String operation) {
    if (responseData is! Map) {
      throw FormatException(
        'Invalid product payload for $operation: expected response body to be a Map, got ${responseData.runtimeType}. Response: $responseData',
      );
    }

    final payload = responseData["data"];
    if (payload == null) {
      throw FormatException(
        'Invalid product payload for $operation: missing "data" object. Response: $responseData',
      );
    }

    if (payload is! Map) {
      throw FormatException(
        'Invalid product payload for $operation: expected "data" to be a Map, got ${payload.runtimeType}. Response: $responseData',
      );
    }

    try {
      return Product.fromJson(Map<String, dynamic>.from(payload));
    } on TypeError catch (error) {
      throw FormatException(
        'Invalid product payload for $operation: unable to convert "data" to Map<String, dynamic>. Error: $error. Response: $responseData',
      );
    }
  }

  static Future<List<Product>> getProducts() async {
    final response = await ApiClient.dio.get("/products");

    final responseData = response.data;
    if (responseData is List) {
      return _parseProductList(responseData, "get products", responseData);
    }
    if (responseData is Map) {
      return _parseProductList(
        responseData["data"],
        "get products",
        responseData,
      );
    }

    throw FormatException(
      'Invalid product payload for get products: expected response body to be a List or a Map containing a "data" List, got ${responseData.runtimeType}. Response: $responseData',
    );
  }

  static Future<Product> getProductById(String id) async {
    final response = await ApiClient.dio.get("/products/$id");

    return _parseSingleProductResponse(response.data, "get product by id");
  }

  static Future<Product> createProduct(Map<String, dynamic> payload) async {
    final response = await ApiClient.dio.post(
      "/products",
      data: payload,
    );

    return _parseSingleProductResponse(response.data, "create product");
  }

  static Future<Product> updateProduct(
      String id, Map<String, dynamic> payload) async {
    final response = await ApiClient.dio.put(
      "/products/$id",
      data: payload,
    );

    return _parseSingleProductResponse(response.data, "update product");
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
