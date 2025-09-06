import 'package:appbanquanao/providers/cart_provider.dart';
import 'package:appbanquanao/screens/main_navigation_screen.dart';
import 'package:appbanquanao/services/product_variant_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ShippingForm extends StatefulWidget {
  final Future<void> Function(
    String receiverName,
    String phone,
    String address,
    String note,
    String? voucherCode,
    String paymentMethod,
  )
  onSubmit;

  const ShippingForm({required this.onSubmit, Key? key}) : super(key: key);

  @override
  _ShippingFormState createState() => _ShippingFormState();
}

class _ShippingFormState extends State<ShippingForm> {
  final _formKey = GlobalKey<FormState>();
  final _receiverController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  final List<String> _paymentMethods = [
    'Thanh toán khi nhận hàng',
    'Ví điện tử',
  ];
  String? _selectedPaymentMethod;

  String? _selectedVoucherCode;
  List<Map<String, String>> _availableVouchers = [];
  bool _isLoadingVouchers = false;
  bool _isSubmitting = false;

  double _discount = 0.0;
  double _totalAmount = 0.0;
  double _finalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
    _fetchAvailableVouchers();
  }

  @override
  void dispose() {
    _receiverController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchAvailableVouchers() async {
    setState(() => _isLoadingVouchers = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:7010/api/Voucher'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _availableVouchers = data.map<Map<String, String>>((voucher) {
            return {
              'code': voucher['code'].toString(),
              'label': '${voucher['code']} - Giảm ${voucher['discount']} đ',
            };
          }).toList();
        });
      } else {
        throw Exception('Không thể tải voucher: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải voucher: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingVouchers = false);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn phương thức thanh toán.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(
        _receiverController.text.trim(),
        _phoneController.text.trim(),
        _addressController.text.trim(),
        _noteController.text.trim(),
        _selectedVoucherCode,
        _selectedPaymentMethod ?? '',
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final userId = prefs.getString('userId') ?? '';

      final cartResponse = await http.get(
        Uri.parse('http://localhost:7010/api/CartItem/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (cartResponse.statusCode == 200) {
        final cartItems = json.decode(cartResponse.body) as List;
        for (var item in cartItems) {
          final variantId = int.parse(item['productVariantId'].toString());
          final quantity = int.parse(item['quantity'].toString());
          final currentStock = int.parse(item['stock']?.toString() ?? '0');
          final newStock = currentStock - quantity;

          await ProductVariantService.updateStock(
            variantId: variantId,
            stock: newStock,
            token: token,
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đặt hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      context.read<CartProvider>().clear();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(initialTab: 0),
        ),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi đặt hàng: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _applyVoucher(String? code) async {
    setState(() => _isLoadingVouchers = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:7010/api/Voucher/apply'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'voucherCode': code, 'cartTotal': _totalAmount}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _discount = (data['Discount'] ?? 0).toDouble();
          _finalAmount =
              (data['TotalAfterDiscount'] ?? (_totalAmount - _discount))
                  .toDouble();
        });
      } else {
        throw Exception('Voucher không hợp lệ.');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi áp dụng mã: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingVouchers = false);
    }
  }

  void _showQrDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Thanh toán qua ví điện tử'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng quét mã QR sau (giả lập):'),
            const SizedBox(height: 12),
            Image.asset(
              'assets/image/demo_qr.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            const Text(
              '(Chỉ dùng để demo thanh toán)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitForm();
            },
            child: const Text('Xác nhận đã thanh toán'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken') ?? '';
      final userId = prefs.getString('userId');

      if (userId == null || userId.isEmpty) {
        throw Exception('Không tìm thấy userId. Vui lòng đăng nhập lại.');
      }

      final response = await http.get(
        Uri.parse('http://localhost:7010/api/CartItem/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        double total = 0.0;
        for (var item in data) {
          total += (item['price'] ?? 0) * (item['quantity'] ?? 0);
        }

        setState(() {
          _totalAmount = total;
          _finalAmount = total;
        });

        if (_selectedVoucherCode != null) {
          await _applyVoucher(_selectedVoucherCode);
        }
      } else {
        throw Exception('Không thể tải giỏ hàng: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi tải giỏ hàng: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Thông tin giao hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _receiverController,
              decoration: const InputDecoration(labelText: 'Tên người nhận'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Vui lòng nhập SĐT' : null,
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Vui lòng nhập địa chỉ'
                  : null,
            ),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
              ),
            ),
            const SizedBox(height: 16),

            // Voucher
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn voucher',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _isLoadingVouchers
                    ? const SizedBox(
                        height: 48,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        value: _selectedVoucherCode,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Không áp dụng voucher'),
                          ),
                          ..._availableVouchers.map(
                            (voucher) => DropdownMenuItem<String>(
                              value: voucher['code'],
                              child: Text(voucher['label'] ?? ''),
                            ),
                          ),
                        ],
                        onChanged: (value) async {
                          setState(() {
                            _selectedVoucherCode = value;
                          });
                          await _applyVoucher(value);
                        },
                      ),
                const SizedBox(height: 12),
              ],
            ),

            const SizedBox(height: 16),

            // Payment method
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phương thức thanh toán',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._paymentMethods.map(
                  (method) => RadioListTile<String>(
                    title: Text(method),
                    value: method,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() => _selectedPaymentMethod = value);
                    },
                  ),
                ),
                if (_selectedVoucherCode != null && _discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Text('Mã giảm giá đã áp dụng: $_selectedVoucherCode'),
                        Text('Giảm: -${_discount.toStringAsFixed(0)} đ'),
                        Text(
                          'Tổng thanh toán: ${_finalAmount.toStringAsFixed(0)} đ',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_selectedPaymentMethod == 'Ví điện tử') {
                          _showQrDialog();
                        } else {
                          _submitForm();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(45),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận đặt hàng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
