import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import 'forms/category_form_screen.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final CategoryService _categoryService = CategoryService();
  final ProductService _productService = ProductService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final categories = await _categoryService.fetchCategories();
      final products = await _productService.fetchProducts();

      setState(() {
        _categories = categories;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Lỗi khi tải danh mục: $e');
      setState(() => _isLoading = false);
    }
  }

  int _getProductCountByCategory(String categoryId) {
    return _products.where((p) => p.categoryId.toString() == categoryId).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: _categories.isEmpty
          ? const Center(
              child: Text(
                'Chưa có danh mục nào',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return _buildCategoryCard(category);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CategoryFormScreen()),
          );
          if (result == true) _loadData(); // Reload list
        },
        backgroundColor: Colors.red[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final productCount = _getProductCountByCategory(category.id.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[100],
          child: Icon(Icons.category, color: Colors.red[600]),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('$productCount sản phẩm'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CategoryFormScreen(category: category),
                  ),
                );
                if (result == true) _loadData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(category, productCount),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Category category, int productCount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          productCount > 0
              ? 'Danh mục "${category.name}" có $productCount sản phẩm. Bạn có chắc muốn xóa?'
              : 'Bạn có chắc muốn xóa danh mục "${category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // đóng AlertDialog trước

              try {
                await _categoryService.deleteCategory(
                  category.id.toString(),
                ); // 👈 gọi API thật

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Đã xóa danh mục "${category.name}"'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData(); // Reload lại danh sách
              } catch (e) {
                debugPrint('❌ Lỗi khi xóa danh mục: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Xóa thất bại. Vui lòng thử lại.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
