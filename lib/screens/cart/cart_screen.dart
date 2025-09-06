import 'package:appbanquanao/models/order.dart';
import 'package:appbanquanao/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isOrdering = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // ignore: use_build_context_synchronously
      Provider.of<CartService>(context, listen: false).loadCart();
    });
  }

  Future<void> _createOrder() async {
    final cartService = Provider.of<CartService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (cartService.items.isEmpty || authService.currentUser == null) return;

    setState(() => _isOrdering = true);

    try {
      // Tạo object Order từ giỏ hàng
      final order = Order(
        id: 0, // hoặc dùng Uuid().v4() nếu bạn cài gói uuid
        userId: int.tryParse(authService.currentUser!.id) ?? 0,
        items: cartService.items,
        totalAmount: cartService.totalAmount,
        discountAmount: 0,
        orderDate: DateTime.now(),
        status: 'Pending',
        receiverName: 'Nguyễn Văn A', // hoặc lấy từ form nhập địa chỉ
        phone: '0123456789', // hoặc từ user profile
        address: '123 Đường ABC', // hoặc từ form
        note: '',
        paymentMethod: 'cod', // hoặc 'momo', 'paypal' tuỳ bạn
      );

      // Gọi API để tạo đơn hàng + trừ kho
      await OrderService.createOrder(order);

      if (!mounted) return;

      // Xóa giỏ hàng sau khi tạo thành công
      await cartService.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Đặt hàng thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi khi đặt hàng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      body: cartService.items.isEmpty
          ? const Center(child: Text('🛍️ Giỏ hàng trống'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartService.items.length,
                    itemBuilder: (context, index) {
                      final item = cartService.items[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              item.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image),
                            ),
                          ),
                          title: Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Size: ${item.size} | Màu: ${item.color}\nSố lượng: ${item.quantity}',
                            style: const TextStyle(height: 1.5),
                          ),
                          trailing: Text(
                            '${item.totalPrice.toStringAsFixed(0)}đ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Tổng cộng: ${cartService.totalAmount.toStringAsFixed(0)}đ',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isOrdering ? null : _createOrder,
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: _isOrdering
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Đặt hàng ngay'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
