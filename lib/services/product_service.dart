import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class ProductService {
  static const String _baseUrl = 'http://localhost:7010/api/Product';

  /// 📦 Lấy token từ SharedPreferences
  Future<String?> _getToken() async =>
      (await SharedPreferences.getInstance()).getString('accessToken');

  /// 🚀 Upload ảnh sản phẩm
  Future<String?> uploadImage(XFile image) async {
    final uri = Uri.parse('$_baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    try {
      final bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );

      final response = await http.Response.fromStream(await request.send());

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['imageUrl'];
      } else {
        throw Exception('❌ Upload thất bại: ${response.body}');
      }
    } catch (e) {
      throw Exception('❌ Lỗi khi upload ảnh: $e');
    }
  }

  /// 🟢 Lấy danh sách sản phẩm (public hoặc theo category)
  Future<List<Product>> fetchProducts({String? categoryId}) async {
    final uri = Uri.parse('$_baseUrl/public').replace(
      queryParameters: categoryId != null ? {'categoryId': categoryId} : null,
    );

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body);
      return list.map<Product>((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('❌ Lỗi khi lấy danh sách: ${response.statusCode}');
    }
  }

  /// 🔍 Lấy sản phẩm theo ID
  Future<Product?> getById(String id) async {
    final token = await _getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200
        ? Product.fromJson(jsonDecode(response.body))
        : null;
  }

  /// ➕ Thêm sản phẩm
  Future<bool> addProduct(Product product) async {
    final token = await _getToken();
    if (token == null || !product.isValid()) return false;

    final response = await http.post(
      Uri.parse('$_baseUrl/Create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson()),
    );

    return response.statusCode == 201;
  }

  /// ✏️ Cập nhật sản phẩm
  Future<bool> updateProduct(Product product) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$_baseUrl/${product.id}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(product.toJson(includeId: true)),
    );

    return response.statusCode == 200;
  }

  /// 🗑️ Xóa sản phẩm
  Future<bool> deleteProduct(String id) async {
    final token = await _getToken();
    if (token == null) return false;

    final response = await http.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 204;
  }

  /// 📂 Lấy sản phẩm theo danh mục (admin)
  Future<List<Product>> getByCategory(String categoryId) async {
    final token = await _getToken();
    if (token == null) return [];

    final response = await http.get(
      Uri.parse('$_baseUrl/category/$categoryId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data.map<Product>((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('❌ Lỗi khi lấy theo danh mục: ${response.body}');
    }
  }

  /// 💵 Lọc sản phẩm theo khoảng giá (public)
  Future<List<Product>> fetchProductsByPrice({
    double? minPrice,
    double? maxPrice,
    String? categoryId,
  }) async {
    final queryParams = <String, String>{};

    if (minPrice != null) {
      queryParams['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['maxPrice'] = maxPrice.toString();
    }
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }

    final uri = Uri.parse(
      '$_baseUrl/public',
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final list = jsonDecode(response.body);
      return list.map<Product>((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('❌ Lỗi khi lọc sản phẩm: ${response.statusCode}');
    }
  }
}
