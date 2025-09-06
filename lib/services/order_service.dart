import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/auth_service.dart';

class OrderService {
  static const String baseUrl = 'http://localhost:7010/api/Order';
  static const String adminOrderUrl = 'http://localhost:7010/api/admin/orders';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<Order>> fetchOrders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      debugPrint("❌ [fetchOrders] Token không tồn tại.");
      return [];
    }

    debugPrint("📡 [fetchOrders] Gửi GET $baseUrl");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    debugPrint("✅ [fetchOrders] Status: ${response.statusCode}");
    debugPrint("✅ [fetchOrders] Body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      debugPrint(
        "❌ [fetchOrders] API lỗi: ${response.statusCode} - ${response.body}",
      );
      return [];
    }
  }

  static Future<List<Order>> getOrdersByUser() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token không tồn tại");

    final url = Uri.parse('$baseUrl/user');

    debugPrint("📡 [getOrdersByUser] Gửi GET $url");

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("✅ [getOrdersByUser] Status: ${response.statusCode}");
    debugPrint("✅ [getOrdersByUser] Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Lấy đơn hàng thất bại: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is List) {
      return decoded.map((json) => Order.fromJson(json)).toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data.map((json) => Order.fromJson(json)).toList();
      }
      throw Exception('Trường "data" không phải danh sách');
    }

    throw Exception('API không trả về danh sách đơn hàng hợp lệ');
  }

  static createOrder(Order order) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token không tồn tại");

    // 1️⃣ Kiểm tra và cập nhật tồn kho từng item
    for (final item in order.items) {
      debugPrint("📡 [createOrder] GET sản phẩm ${item.productId}");
      final productRes = await http.get(
        Uri.parse('http://localhost:7010/api/Product/${item.productId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("✅ [createOrder] Status: ${productRes.statusCode}");
      debugPrint("✅ [createOrder] Body: ${productRes.body}");

      if (productRes.statusCode != 200) {
        throw Exception('❌ Không tìm thấy sản phẩm ID ${item.productId}');
      }

      final productData = jsonDecode(productRes.body);
      final List variants = productData['variants'];

      final matchedVariant = variants.firstWhere(
        (v) =>
            v['size'].toString() == item.size.toString() &&
            v['color'].toString() == item.color.toString(),
        orElse: () => throw Exception(
          '❌ Không tìm thấy biến thể (size: ${item.size}, color: ${item.color})',
        ),
      );

      final variantId = matchedVariant['id'];
      final currentStock = matchedVariant['stock'] as int;

      debugPrint("ℹ️ [createOrder] Tồn kho hiện tại: $currentStock");

      if (currentStock < item.quantity) {
        throw Exception(
          '❌ Số lượng tồn kho không đủ (còn $currentStock, cần ${item.quantity})',
        );
      }

      await updateVariantStock(
        variantId,
        matchedVariant,
        currentStock - item.quantity,
        token,
      );
    }

    // 2️⃣ Tạo đơn hàng trên server
    final orderPayload = {
  "userId": order.userId,
  "totalAmount": order.totalAmount,
  "items": order.items
      .map(
        (item) => {
          "productId": item.productId,
          "quantity": item.quantity,
          "size": item.size,
          "color": item.color,
        },
      )
      .toList(),
};


    debugPrint(
      "📡 [createOrder] POST tạo đơn hàng: ${jsonEncode(orderPayload)}",
    );

    final createOrderRes = await http.post(
      Uri.parse('http://localhost:7010/api/Order'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(orderPayload),
    );

    debugPrint("✅ [createOrder] POST Status: ${createOrderRes.statusCode}");
    debugPrint("✅ [createOrder] Body: ${createOrderRes.body}");

    if (createOrderRes.statusCode != 200 && createOrderRes.statusCode != 201) {
      throw Exception('❌ Lỗi tạo đơn hàng: ${createOrderRes.body}');
    }
  }

  static Future<void> updateVariantStock(
    String variantId,
    Map<String, dynamic> matchedVariant,
    int newStock,
    String token,
  ) async {
    final updatePayload = {
      "id": variantId,
      "productId": matchedVariant["productId"],
      "size": matchedVariant["size"],
      "color": matchedVariant["color"],
      "stock": newStock,
    };

    debugPrint("📡 [updateVariantStock] PUT tồn kho variantId=$variantId");
    debugPrint("📝 Payload: ${jsonEncode(updatePayload)}");

    final res = await http.put(
      Uri.parse('http://localhost:7010/api/ProductVariant/$variantId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updatePayload),
    );

    debugPrint("✅ [updateVariantStock] Status: ${res.statusCode}");
    debugPrint("✅ [updateVariantStock] Body: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('❌ Lỗi cập nhật kho biến thể: ${res.body}');
    }
  }

  static Future<List<Order>> getAllOrdersForAdmin() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token không tồn tại");

    final response = await http.get(
      Uri.parse(adminOrderUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("✅ [getAllOrdersForAdmin] Status: ${response.statusCode}");
    debugPrint("✅ [getAllOrdersForAdmin] Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Lỗi lấy danh sách đơn hàng: ${response.body}');
    }

    final data = jsonDecode(response.body);
    if (data is List) {
      return data.map((json) => Order.fromJson(json)).toList();
    }

    throw Exception('API không trả về danh sách đơn hàng hợp lệ');
  }

  static Future<void> updateOrderStatus(Order order, String newStatus) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token không tồn tại");

    final url = Uri.parse('$adminOrderUrl/${order.id}/status');
    final payload = {"status": newStatus};

    debugPrint("📡 [updateOrderStatus] PUT $url");
    debugPrint("📝 Payload: ${jsonEncode(payload)}");

    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    debugPrint("✅ [updateOrderStatus] Status: ${res.statusCode}");
    debugPrint("✅ [updateOrderStatus] Body: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception('Lỗi cập nhật trạng thái: ${res.body}');
    }
  }

  static Future<bool> deleteOrder(Order order) async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception("Token không tồn tại");

    final url = Uri.parse('$adminOrderUrl/${order.id}');
    debugPrint("📡 [deleteOrder] DELETE $url");

    final res = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    debugPrint("✅ [deleteOrder] Status: ${res.statusCode}");
    debugPrint("✅ [deleteOrder] Body: ${res.body}");

    if (res.statusCode == 200 || res.statusCode == 204) {
      return true;
    }

    return false;
  }
  static Future<int> getVariantId(int productId, String size, String color) async {
  // Ví dụ gọi API để lấy variantId từ server
  final response = await http.get(
    Uri.parse('http://localhost:7010/api/ProductVariants/get-variant-id?productId=$productId&size=$size&color=$color'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['variantId'] as int;
  } else {
    throw Exception('Failed to fetch variantId');
  }
}

}
