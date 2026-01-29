import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../services/database_service.dart';

class ProductProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
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
    _error = null;

    try {
      _products = await _db.getAllProducts();
      _lowStockProducts = await _db.getLowStockProducts();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      await loadProducts();
      return;
    }

    _isLoading = true;

    try {
      _products = await _db.searchProducts(query);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
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
      final product = Product(
        id: const Uuid().v4(),
        name: name,
        description: description,
        category: category,
        barcode: barcode,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        stock: stock,
        lowStockAlert: lowStockAlert,
        unit: unit,
      );

      await _db.insertProduct(product);
      _products.insert(0, product);
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
      await _db.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
      }
      if (_selectedProduct?.id == product.id) {
        _selectedProduct = product;
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
      await _db.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
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

  Future<bool> updateStock(String productId, int quantity, {bool isDeduct = true}) async {
    try {
      await _db.updateStock(productId, quantity, isDeduct);
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