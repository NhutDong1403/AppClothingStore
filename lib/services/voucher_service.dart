import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/voucher.dart';

class VoucherService {
  final String baseUrl =
      'http://localhost:7010/api/Voucher'; // ⚠️ Đổi lại nếu dùng IP thật

  Future<List<Voucher>> fetchVouchers() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Voucher.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách voucher');
    }
  }

  Future<void> addVoucher(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Không thể thêm voucher');
    }
  }

  Future<void> deleteVoucher(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Không thể xoá voucher');
    }
  }

  Future<void> updateVoucher(Voucher voucher) async {
    print('🔄 Updating voucher with ID: ${voucher.id}');
    print('📦 Data: ${json.encode(voucher.toJson())}');
    final response = await http.put(
      Uri.parse('$baseUrl/${voucher.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(voucher.toJson()),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Không thể cập nhật voucher');
    }
  }
}
