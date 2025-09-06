import 'package:appbanquanao/models/cart_item.dart';
import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/user.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import '../../services/product_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isLoading = true;
  List<Order> _orders = [];
  Map<String, User> _userMap = {};
  Map<String, Product> _productMap = {};

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      final orders = await OrderService.getAllOrdersForAdmin();

      // 🎯 Print debug JSON các items
      for (final order in orders) {
        for (final item in order.items) {
          print(
            'DEBUG đơn hàng #${order.id}: '
            'productId=${item.productId}, '
            'productName=${item.productName}, '
            'size=${item.size}, '
            'color=${item.color}, '
            'quantity=${item.quantity}, '
            'price=${item.price}',
          );
        }
      }

      final users = await UserService.fetchUsers();
      final products = await ProductService().fetchProducts();

      setState(() {
        _orders = orders;
        _userMap = {for (var u in users) u.id.toString(): u};
        _productMap = {for (var p in products) p.id.toString(): p};
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _showSnackbar('❌ Lỗi tải dữ liệu: $e', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await OrderService.updateOrderStatus(order, newStatus);
      await _loadAllData();
      if (mounted) {
        _showSnackbar('✅ Cập nhật trạng thái thành công', Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('❌ Lỗi cập nhật trạng thái: $e', Colors.red);
      }
    }
  }

  Future<void> _deleteOrder(Order order) async {
    final confirmed = await OrderService.deleteOrder(order);
    if (!mounted) return;
    if (confirmed) {
      await _loadAllData();
      _showSnackbar('✅ Đã xoá đơn hàng #${order.id}', Colors.green);
    } else {
      _showSnackbar('❌ Xoá đơn hàng thất bại', Colors.red);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'đang xử lý':
        return Colors.orange;
      case 'đang giao':
        return Colors.blue;
      case 'hoàn thành':
        return Colors.green;
      case 'đã huỷ':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Chưa có đơn hàng nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    final totalAfterDiscount = order.totalAmount - order.discountAmount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Đơn hàng #${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  color: _getStatusColor(order.status),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Khách hàng: ${order.receiverName}'),
            Text('SĐT: ${order.phone}'),
            Text('Địa chỉ: ${order.address}'),
            if (order.note.isNotEmpty) Text('Ghi chú: ${order.note}'),
            Text('Ngày đặt: ${_formatDate(order.orderDate)}'),
            if (order.voucherCode?.isNotEmpty == true)
              Text(
                'Mã giảm giá: ${order.voucherCode}',
                style: const TextStyle(color: Colors.green),
              ),
            Text(
              'Tổng tiền: ${order.totalAmount.toStringAsFixed(0)}đ',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (order.discountAmount > 0)
              Text(
                'Giảm giá: -${order.discountAmount.toStringAsFixed(0)}đ',
                style: const TextStyle(color: Colors.green),
              ),
            Text(
              'Thành tiền: ${totalAfterDiscount.toStringAsFixed(0)}đ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiết đơn hàng:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...order.items.map(_buildOrderItem),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showOrderStatusDialog(order),
                        child: const Text('Cập nhật trạng thái'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _showDeleteConfirmation(order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Xoá đơn hàng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    final product = _productMap[item.productId];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Ảnh sản phẩm
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product != null
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                    )
                  : const Icon(Icons.image, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),

          // Thông tin sản phẩm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),

                // Màu và size đã chọn
                Row(
                  children: [
                    Text(
                      'Màu: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      item.color.isNotEmpty ? item.color : 'Không có',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Size: ',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      item.size.isNotEmpty ? item.size : 'Không có',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Số lượng và đơn giá
                Text(
                  'SL: ${item.quantity} x ${item.price.toStringAsFixed(0)}đ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Tổng tiền từng item
          Text(
            '${item.totalPrice.toStringAsFixed(0)}đ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showOrderStatusDialog(Order order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Cập nhật trạng thái đơn hàng #${order.id}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'Đang xử lý',
            'Đang giao',
            'Hoàn thành',
            'Đã huỷ',
          ].map((status) => _statusOption(status, order)).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _statusOption(String status, Order order) {
    return ListTile(
      leading: Icon(Icons.circle, color: _getStatusColor(status)),
      title: Text(status),
      onTap: () async {
        Navigator.pop(context);
        await _updateOrderStatus(order, status);
      },
    );
  }

  void _showDeleteConfirmation(Order order) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xoá'),
        content: Text('Bạn có chắc muốn xoá đơn hàng #${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteOrder(order);
            },
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
  }
}
