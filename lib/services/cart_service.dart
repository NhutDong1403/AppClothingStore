import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';

class CartService with ChangeNotifier {
  List<CartItem> _items = [];

  List<CartItem> get items => _items;

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  int get uniqueItemCount => _items.length;

  double get totalAmount =>
      _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

  /// Thêm sản phẩm lên API
  Future<void> addToCartAPI(int productId, int quantity) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      throw Exception("Bạn chưa đăng nhập. Vui lòng đăng nhập trước.");
    }

    final url = Uri.parse("http://localhost:7010/api/CartItem");
    final body = jsonEncode({"productId": productId, "quantity": quantity});
    print('👉 Gửi POST: $url');
    print('👉 Body: $body');

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: body,
    );

    print('👉 Status code: ${response.statusCode}');
    print('👉 Response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception("Failed to add to cart: ${response.body}");
    }
  }

  /// Lấy giỏ hàng từ API
  Future<void> loadCartFromAPI(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    if (token == null) {
      throw Exception("Bạn chưa đăng nhập.");
    }

    final url = Uri.parse("http://localhost:7010/api/CartItem/$userId");

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final List decoded = jsonDecode(response.body);
      _items = decoded.map((e) => CartItem.fromJson(e)).toList();
      notifyListeners();
    } else {
      throw Exception("Không lấy được giỏ hàng: ${response.body}");
    }
  }

  /// Cập nhật số lượng local
  Future<void> updateQuantity(
    int productId,
    String size,
    String color,
    int newQuantity,
  ) async {
    final index = _items.indexWhere(
      (item) =>
          item.productId == productId &&
          item.size == size &&
          item.color == color,
    );
    if (index >= 0) {
      if (newQuantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = newQuantity;
      }
      await saveCart();
      notifyListeners();
    }
  }

  /// Xóa sản phẩm local
  Future<void> removeFromCart(int productId, String size, String color) async {
    _items.removeWhere(
      (item) =>
          item.productId == productId &&
          item.size == size &&
          item.color == color,
    );
    await saveCart();
    notifyListeners();
  }

  /// Xóa toàn bộ local
  Future<void> clearCart() async {
    _items.clear();
    await saveCart();
    notifyListeners();
  }

  /// Lưu local storage
  Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString('cart', cartJson);
  }

  /// Tải local storage
  Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null) {
      final decoded = jsonDecode(cartString) as List;
      _items = decoded.map((json) => CartItem.fromJson(json)).toList();
      notifyListeners();
    }
  }

  /// Thêm sản phẩm local
  void addToCart(CartItem newItem) {
    final index = _items.indexWhere(
      (item) =>
          item.productId == newItem.productId &&
          item.size == newItem.size &&
          item.color == newItem.color,
    );

    if (index >= 0) {
      _items[index].quantity += newItem.quantity;
    } else {
      _items.add(newItem);
    }

    saveCart();
    notifyListeners();
  }
}
