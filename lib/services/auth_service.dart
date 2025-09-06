import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  static const String baseUrl =
      'http://localhost:7010/api/Auth'; // ✅ dùng IP loopback nếu dùng HTTPS

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  static const _tokenKey = 'accessToken';
  static const _userIdKey = 'userId';

  // ✅ Lấy token từ SharedPreferences (có thể gọi từ nơi khác)
  static Future<String?> getToken() async {
    print("🔍 Bắt đầu lấy token...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print("✅ Token lấy được: $token");
      return token;
    } catch (e) {
      print("❌ Lỗi khi lấy token: $e");
      return null;
    }
  }

  // ✅ Lấy userId từ SharedPreferences
  static Future<String?> getUserId() async {
    print("🔍 Bắt đầu lấy userId...");
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      print("✅ userId lấy được: $userId");
      return userId;
    } catch (e) {
      print("❌ Lỗi khi lấy userId: $e");
      return null;
    }
  }

  // ✅ Lưu token và userId vào SharedPreferences
  Future<void> saveTokenAndUserId(String token, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
    print("💾 Token và userId đã được lưu: $token / $userId");
  }

  // ✅ Xóa token và userId khi logout
  static Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    print("🧹 Token và userId đã được xóa");
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        // Lưu token và userId
        await saveTokenAndUserId(_token!, _currentUser!.id);

        notifyListeners();
        return true;
      } else {
        debugPrint('Đăng nhập thất bại: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Lỗi khi gọi API đăng ký: $e');
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    final token = _token ?? await getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Lỗi đổi mật khẩu: $e');
      return false;
    }
  }

  void logout() async {
    _currentUser = null;
    _token = null;
    await clearStorage();
    notifyListeners();
  }
}
