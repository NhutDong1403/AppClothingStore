import 'package:appbanquanao/services/product_service.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {

  final ProductService service;
  ProductProvider({required this.service});
  final List<Product> _products = [];

  List<Product> get products => List.unmodifiable(_products);

  Future<void> fetchAllProducts() async {
    final fetched = await service.fetchProducts();
    _products
      ..clear()
      ..addAll(fetched);
    notifyListeners();
  }

  Future<void> fetchProductById(String id) async {
    final product = await service.getById(id);
    final index = _products.indexWhere((p) => p.id == id);
    if (product != null) {
      if (index == -1) {
        _products.add(product);
      } else {
        _products[index] = product;
      }
      notifyListeners();
    }
  }

  void setProducts(List<Product> products) {
    _products
      ..clear()
      ..addAll(products);
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _products[index] = updated;
      notifyListeners();
    }
  }

  Product? getProductById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _products.clear();
    notifyListeners();
  }
}
