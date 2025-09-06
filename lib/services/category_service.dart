import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';

class CategoryService {
  static const String baseUrl = 'http://localhost:7010/api/Category';

  /// Lấy token từ SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  /// 🔓 Người dùng - Lấy danh mục (không cần token)
  Future<List<Category>> fetchCategories() async {
    final uri = Uri.parse('$baseUrl/public');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded.map((json) => Category.fromJson(json)).toList();
      } else if (decoded is Map && decoded['data'] is List) {
        return (decoded['data'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
      } else if (decoded is Map && decoded[r'$values'] is List) {
        // 🟢 Đây là trường hợp bạn gặp
        return (decoded[r'$values'] as List)
            .map((json) => Category.fromJson(json))
            .toList();
      } else {
        throw Exception('❌ Không đúng định dạng danh sách danh mục.');
      }
    } else {
      throw Exception('❌ Lỗi HTTP ${response.statusCode}');
    }
  }

  /// ➕ Admin - Thêm danh mục mới
  Future<bool> addCategory(String name) async {
    final token = await _getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/Create'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    return response.statusCode == 201;
  }

  /// 🔄 Admin - Cập nhật danh mục
  Future<bool> updateCategory(int id, String name) async {
    final token = await _getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    return response.statusCode == 200;
  }

  /// ❌ Admin - Xoá danh mục
  Future<void> deleteCategory(String id) async {
    final token = await _getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('❌ Xoá danh mục thất bại');
    }
  }

  /// 🔍 Lấy danh mục theo ID (tuỳ vào backend có hỗ trợ hay không)
  Future<Category?> getById(String id) async {
    final uri = Uri.parse('$baseUrl/$id');

    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('❌ Lỗi HTTP ${response.statusCode}');
    }
  }
}
