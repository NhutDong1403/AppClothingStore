import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserService {
  static const String baseUrl = 'http://localhost:7010/api/User'; // Đổi nếu backend khác

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken'); // Khớp key với AuthService.saveToken()
  }

  static Future<List<User>> fetchUsers() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('❌ Không tìm thấy token');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('❌ API trả về lỗi: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi khi tải danh sách người dùng: $e');
    }
  }
}
