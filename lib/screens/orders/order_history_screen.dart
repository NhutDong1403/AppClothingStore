import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../../main.dart'; // routeObserver

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with RouteAware {
  Future<List<Order>>? _futureOrders;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _futureOrders = user != null
        ? OrderService.getOrdersByUser()
        : Future.value([]);
    setState(() {});
  }

  Future<void> _reloadOrders() async {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user != null) {
      final newOrders = await OrderService.getOrdersByUser();
      setState(() {
        _futureOrders = Future.value(newOrders);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _reloadOrders();
  }

  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return formatter.format(amount);
  }

  String formatDate(DateTime dateTime) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(dateTime);
  }

  Widget buildStatusTag(String status) {
    Color backgroundColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'đang giao':
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        label = 'Đang giao';
        break;
      case 'hoàn thành':
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        label = 'Hoàn thành';
        break;
      case 'đã huỷ':
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        label = 'Đã huỷ';
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.black54;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthService>(
        builder: (context, authService, _) {
          if (authService.currentUser == null) {
            return const Center(
              child: Text('Vui lòng đăng nhập để xem đơn hàng'),
            );
          }

          return FutureBuilder<List<Order>>(
            future: _futureOrders,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                return const Center(child: Text('Chưa có đơn hàng nào'));
              }

              final orders = snapshot.data!;
              return RefreshIndicator(
                onRefresh: _reloadOrders,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Đơn hàng #${order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                buildStatusTag(order.status),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('🗓 Ngày đặt: ${formatDate(order.orderDate)}'),
                            const Divider(height: 20),

                            Text('👤 Người nhận: ${order.receiverName}'),
                            Text('📞 SĐT: ${order.phone}'),
                            Text('📍 Địa chỉ: ${order.address}'),
                            if ((order.note).isNotEmpty)
                              Text('📝 Ghi chú: ${order.note}'),
                            const SizedBox(height: 10),

                            Text('💳 Thanh toán: ${order.paymentMethod}'),
                            if ((order.voucherCode ?? '').isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer,
                                    size: 18,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Voucher: ${order.voucherCode}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if ((order.voucherDescription ?? '').isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 28.0,
                                    top: 2,
                                  ),
                                  child: Text(
                                    order.voucherDescription!,
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 10),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tổng tiền trước giảm: ${formatCurrency(order.totalAmount + order.discountAmount)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (order.discountAmount > 0)
                                  Text(
                                    'Giảm giá voucher: -${formatCurrency(order.discountAmount)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tổng thanh toán: ${formatCurrency(order.totalAmount)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),

                            const Divider(height: 20),

                            const Text(
                              '📦 Sản phẩm:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),

                            ...order.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.productName} x${item.quantity}',
                                      ),
                                    ),
                                    Text(formatCurrency(item.price)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
