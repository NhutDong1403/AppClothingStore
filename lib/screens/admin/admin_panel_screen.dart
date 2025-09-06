import 'package:appbanquanao/screens/admin/admin_vouchers_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../services/order_service.dart';
import '../../services/user_service.dart';
import '../auth/login_screen.dart';
import 'admin_products_screen.dart'; // Gợi ý: mở màn hình quản lý nếu cần

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  int _productCount = 0;
  int _categoryCount = 0;
  int _userCount = 0;
  int _orderCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final products = await ProductService().fetchProducts();
      final categories = await CategoryService().fetchCategories();
      final users = await UserService.fetchUsers();
      final orders = await OrderService.fetchOrders();

      setState(() {
        _productCount = products.length;
        _categoryCount = categories.length;
        _userCount = users.length;
        _orderCount = orders.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải dữ liệu dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                Provider.of<AuthService>(context, listen: false).logout();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Đăng xuất'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    title: 'Quản lý Sản phẩm',
                    subtitle: '$_productCount sản phẩm',
                    icon: Icons.inventory,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminProductsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildAdminCard(
                    title: 'Quản lý Danh mục',
                    subtitle: '$_categoryCount danh mục',
                    icon: Icons.category,
                    color: Colors.green,
                    onTap: () {
                      _showFeatureNotImplemented('Quản lý Danh mục');
                    },
                  ),
                  _buildAdminCard(
                    title: 'Quản lý Người dùng',
                    subtitle: '$_userCount người dùng',
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: () {
                      _showFeatureNotImplemented('Quản lý Người dùng');
                    },
                  ),
                  _buildAdminCard(
                    title: 'Quản lý Đơn hàng',
                    subtitle: '$_orderCount đơn hàng',
                    icon: Icons.shopping_cart,
                    color: Colors.purple,
                    onTap: () {
                      _showFeatureNotImplemented('Quản lý Đơn hàng');
                    },
                  ),
                  _buildAdminCard(
                    title: 'Quản lý Voucher',
                    subtitle: 'Danh sách voucher',
                    icon: Icons.card_giftcard,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminVoucherScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAdminCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeatureNotImplemented(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: Text(
          'Tính năng $feature sẽ được phát triển trong phiên bản tiếp theo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
