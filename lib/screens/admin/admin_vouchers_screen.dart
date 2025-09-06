import 'package:flutter/material.dart';
import '../../models/voucher.dart';
import '../../services/voucher_service.dart';

class AdminVoucherScreen extends StatefulWidget {
  const AdminVoucherScreen({super.key});

  @override
  State<AdminVoucherScreen> createState() => _AdminVoucherScreenState();
}

class _AdminVoucherScreenState extends State<AdminVoucherScreen> {
  final VoucherService _voucherService = VoucherService();
  List<Voucher> vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    try {
      final data = await _voucherService.fetchVouchers();
      setState(() {
        vouchers = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi load voucher: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addVoucher(
    String code,
    String description,
    String discount,
  ) async {
    try {
      final newVoucher = {
        "code": code,
        "description": description,
        "discount": discount,
        "isActive": true,
        "createdAt": DateTime.now().toIso8601String(),
      };
      await _voucherService.addVoucher(newVoucher);
      await _loadVouchers(); // Load lại danh sách
    } catch (e) {
      debugPrint('Lỗi khi thêm voucher: $e');
    }
  }

  Future<void> _deleteVoucher(int id) async {
    try {
      await _voucherService.deleteVoucher(id);
      await _loadVouchers();
    } catch (e) {
      debugPrint('Lỗi khi xoá voucher: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Voucher'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
        onPressed: _showAddVoucherDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : vouchers.isEmpty
          ? const Center(child: Text('Chưa có voucher nào.'))
          : ListView.builder(
              itemCount: vouchers.length,
              itemBuilder: (context, index) {
                final voucher = vouchers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.card_giftcard,
                      color: voucher.isActive ? Colors.green : Colors.grey,
                    ),
                    title: Text(
                      '${voucher.code} - ${_formatDiscount(voucher.discount)}',
                    ),

                    subtitle: Text(voucher.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: voucher.isActive,
                          onChanged: (value) async {
                            final updatedVoucher = voucher.copyWith(
                              isActive: value,
                            );
                            try {
                              await _voucherService.updateVoucher(
                                updatedVoucher,
                              );
                              await _loadVouchers();
                            } catch (e) {
                              debugPrint(
                                'Lỗi khi cập nhật trạng thái voucher: $e',
                              );
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _showEditVoucherDialog(voucher);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteVoucher(voucher.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditVoucherDialog(Voucher voucher) {
    final codeController = TextEditingController(text: voucher.code);
    final descriptionController = TextEditingController(
      text: voucher.description,
    );
    final discountController = TextEditingController(text: voucher.discount);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Mã voucher'),
              controller: codeController,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Mô tả'),
              controller: descriptionController,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Giảm giá'),
              controller: discountController,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Lưu'),
            onPressed: () async {
              Navigator.pop(context);

              final updatedVoucher = Voucher(
                id: voucher.id,
                code: codeController.text,
                description: descriptionController.text,
                discount: discountController.text,
                isActive: voucher.isActive,
                createdAt: voucher.createdAt,
              );

              try {
                await _voucherService.updateVoucher(updatedVoucher);
                await _loadVouchers();
              } catch (e) {
                debugPrint('Lỗi khi cập nhật voucher: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddVoucherDialog() {
    String code = '';
    String description = '';
    String discount = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Voucher'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Mã voucher'),
              onChanged: (value) => code = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Mô tả'),
              onChanged: (value) => description = value,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Giảm giá'),
              onChanged: (value) => discount = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Thêm'),
            onPressed: () async {
              Navigator.pop(context);
              await _addVoucher(code, description, discount);
            },
          ),
        ],
      ),
    );
  }

  String _formatDiscount(String discount) {
    try {
      final parsed = double.parse(discount);
      // Nếu discount <= 1, coi như tỷ lệ phần trăm (0.2 -> 20%)
      if (parsed <= 1) {
        return '${(parsed * 100).toStringAsFixed(0)}%';
      }
      // Nếu discount >1, coi như số tiền giảm
      return '$parsed';
    } catch (e) {
      // Nếu không parse được thì trả nguyên chuỗi
      return discount;
    }
  }
}
