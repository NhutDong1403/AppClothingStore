import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductVariantService {
  static const String baseUrl = 'http://localhost:7010/api/ProductVariants';

  /// Lấy tất cả biến thể sản phẩm
  static Future<List<dynamic>> getProductVariants({String? token}) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load product variants: ${response.body}');
    }
  }

  /// Lấy biến thể theo productId
  static Future<List<dynamic>> getVariantsByProduct(
    int productId, {
    String? token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/by-product/$productId'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to load variants for product $productId: ${response.body}',
      );
    }
  }

  /// Tạo biến thể mới
  static Future<void> createProductVariant(
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create product variant: ${response.body}');
    }
  }

  /// Cập nhật biến thể
  static Future<void> updateProductVariant(
    int id,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update variant: ${response.body}');
    }
  }

  /// Xóa biến thể
  static Future<void> deleteProductVariant(int id, {String? token}) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete variant: ${response.body}');
    }
  }

  /// Cập nhật tồn kho
  static Future<void> updateStock({
    required int variantId,
    required int stock,
    required String token,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$variantId/stock'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'stock': stock}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update stock: ${response.body}');
    }
  }
}
