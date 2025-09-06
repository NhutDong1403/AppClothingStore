import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';
import '../../providers/product_provider.dart';
import '../product/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  late Future<List<Category>> _futureCategories;
  String? _selectedCategoryId;
  bool _isLoadingProducts = false;

  double _minPrice = 0;
  double _maxPrice = 1000000;
  RangeValues _currentRangeValues = const RangeValues(0, 1000000);

  @override
  void initState() {
    super.initState();
    _futureCategories = _categoryService.fetchCategories();
    _fetchAndSetProducts(); // Lấy dữ liệu ban đầu
  }

  Future<void> _fetchAndSetProducts({String? categoryId}) async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final products = await _productService.fetchProductsByPrice(
        minPrice: _currentRangeValues.start,
        maxPrice: _currentRangeValues.end,
        categoryId: categoryId,
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.setProducts(products);

      setState(() {
        _selectedCategoryId = categoryId;
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi fetch sản phẩm: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        backgroundColor: const Color.fromARGB(255, 182, 221, 255),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Lọc danh mục
          FutureBuilder<List<Category>>(
            future: _futureCategories,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                );
              } else if (snapshot.hasError) {
                return const Text('Lỗi khi tải danh mục');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('Không có danh mục');
              }

              final categories = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Danh mục
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildCategoryChip('Tất cả', null),
                        const SizedBox(width: 8),
                        ...categories.map(
                          (category) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildCategoryChip(
                              category.name,
                              category.id.toString(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Khoảng giá
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Khoảng giá',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        RangeSlider(
                          values: _currentRangeValues,
                          min: _minPrice,
                          max: _maxPrice,
                          divisions: 20,
                          labels: RangeLabels(
                            '${_currentRangeValues.start.toStringAsFixed(0)}đ',
                            '${_currentRangeValues.end.toStringAsFixed(0)}đ',
                          ),
                          onChanged: (values) {
                            setState(() {
                              _currentRangeValues = values;
                            });
                            _fetchAndSetProducts(
                              categoryId: _selectedCategoryId,
                            );
                          },
                          onChangeEnd: null,
                          activeColor: Colors.blue[600],
                          inactiveColor: Colors.grey[300],                  
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Danh sách sản phẩm
          Expanded(
            child: _isLoadingProducts
                ? const Center(child: CircularProgressIndicator())
                : Consumer<ProductProvider>(
                    builder: (context, provider, child) {
                      final products = provider.products;

                      if (products.isEmpty) {
                        return const Center(
                          child: Text('Không có sản phẩm nào'),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => _fetchAndSetProducts(
                          categoryId: _selectedCategoryId,
                        ),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            return _buildProductCard(products[index]);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String name, String? categoryId) {
    final isSelected = _selectedCategoryId == categoryId;
    return FilterChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (selected) {
        if (!selected && _selectedCategoryId == null) return;
        _fetchAndSetProducts(categoryId: selected ? categoryId : null);
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[600],
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final categories = await _futureCategories;
          final categoryName =
              categories
                  .firstWhereOrNull((c) => c.id == product.categoryId)
                  ?.name ??
              '';

          final updatedProduct = await Navigator.push<Product>(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(
                product: product,
                categoryName: categoryName,
              ),
            ),
          );

          if (updatedProduct != null) {
            // Cập nhật lại danh sách sản phẩm sau khi quay về
            await _fetchAndSetProducts(categoryId: _selectedCategoryId);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hình ảnh
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            // Thông tin
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)}đ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[600],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 0 ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.stock > 0 ? 'Còn hàng' : 'Hết hàng',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
