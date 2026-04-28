import 'package:flutter/foundation.dart';
import 'package:khata/models/product.dart';
import 'package:khata/models/product.dart';
import 'package:khata/services/api_services/product_api_service.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _allProducts = [];
  int _searchSeq = 0;
  List<Product> _products = [];
  List<Product> _lowStockProducts = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  List<Product> get lowStockProducts => _lowStockProducts;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allProducts = await ProductApiService.getProducts();
       _products = List<Product>.from(_allProducts);
      print("PRODUCT COUNT: ${_products.length}");
      _lowStockProducts = _products.where((p) => p.isLowStock).toList();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    final seq = ++_searchSeq;
    final q = query.trim().toLowerCase();
    if (_allProducts.isEmpty) await loadProducts();
    if (seq != _searchSeq) return; // drop stale async result
    _products = q.isEmpty
      ? List<Product>.from(_allProducts)
      : _allProducts
        .where((p) =>
          p.name.toLowerCase().contains(q) ||
          (p.barcode ?? '').toLowerCase().contains(q))
        .toList();
    _lowStockProducts = _products.where((p) => p.isLowStock).toList();
    notifyListeners();
  }

  Future<Product?> addProduct({
    required String name,
    String? description,
    String? category,
    String? barcode,
    required double purchasePrice,
    required double sellingPrice,
    int stock = 0,
    int lowStockAlert = 10,
    String unit = 'pcs',
  }) async {
    try {
      final payload = {
        "name": name,
        "description": description,
        "category": category,
        "barcode": barcode,
        "purchasePrice": purchasePrice,
        "sellingPrice": sellingPrice,
        "stock": stock,
        "lowStockAlert": lowStockAlert,
        "unit": unit,
      };

      final product = await ProductApiService.createProduct(payload);

      _products.insert(0, product);
      _lowStockProducts = _products.where((p) => p.isLowStock).toList();
      notifyListeners();
      return product;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final payload = {
        "name": product.name,
        "description": product.description,
        "category": product.category,
        "barcode": product.barcode,
        "purchasePrice": product.purchasePrice,
        "sellingPrice": product.sellingPrice,
        "stock": product.stock,
        "lowStockAlert": product.lowStockAlert,
        "unit": product.unit,
      };

      final updatedProduct =
          await ProductApiService.updateProduct(product.id, payload);

      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _lowStockProducts = _products.where((p) => p.isLowStock).toList();
      if (_selectedProduct?.id == product.id) {
        _selectedProduct = updatedProduct;
      }
      notifyListeners();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      await ProductApiService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _lowStockProducts = _products.where((p) => p.isLowStock).toList();
      if (_selectedProduct?.id == id) {
        _selectedProduct = null;
      }
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStock(String productId, int quantity,
      {bool isDeduct = true}) async {
    try {
      await ProductApiService.updateStock(productId, quantity, isDeduct);
      await loadProducts();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void selectProduct(Product product) {
    _selectedProduct = product;
    notifyListeners();
  }

  void clearSelectedProduct() {
    _selectedProduct = null;
    notifyListeners();
  }

  List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  List<String> get categories {
    return _products
        .where((p) => p.category != null)
        .map((p) => p.category!)
        .toSet()
        .toList();
  }
}
