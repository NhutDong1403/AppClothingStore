import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../product/product_detail_screen.dart';

class HomeContentScreen extends StatefulWidget {
  const HomeContentScreen({super.key});

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;
  late Timer _bannerTimer;

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  int _selectedCategoryId = 0;

  final CategoryService _categoryService = CategoryService();

  // Bổ sung biến lọc giá
  RangeValues _currentRangeValues = const RangeValues(0, 1000000);

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startBannerTimer();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final fetched = await _categoryService.fetchCategories();
      setState(() {
        _categories = [Category(id: 0, name: 'Tất cả'), ...fetched];
      });
    } catch (e) {
      print('Lỗi khi lấy danh mục: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      final products = await ProductService().fetchProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filterProducts();
      });
    } catch (e) {
      debugPrint('❌ Lỗi khi tải dữ liệu: $e');
    }
  }

  @override
  void dispose() {
    _bannerTimer.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        int nextPage = (_currentBannerIndex + 1) % 3;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        final inCategory =
            _selectedCategoryId == 0 || p.categoryId == _selectedCategoryId;
        final inPrice =
            p.price >= _currentRangeValues.start &&
            p.price <= _currentRangeValues.end;
        return inCategory && inPrice;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.7,
          colors: [
            Color.fromARGB(172, 157, 157, 157),
            Color.fromARGB(176, 209, 183, 89),
          ],
          stops: [0.1, 1],
        ),
      ),
      child: Column(
        children: [
          _buildPromotionBanner(),
          _buildCategorySelector(),
          const SizedBox(height: 12),
          _buildPriceRangeSelector(), // Thêm RangeSlider lọc giá
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            SizedBox(width: 8),
                            Text(
                              'Lọc theo danh mục',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2,
                          width: double.infinity,
                          color: const Color.fromARGB(
                            255,
                            0,
                            0,
                            0,
                          ).withOpacity(0.6),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 380,
                        ),
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(product);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionBanner() {
    /* giữ nguyên */
    final List<Map<String, String>> banners = [
      {
        'title': 'FLASH SALE 50%',
        'subtitle': 'Giảm giá tất cả sản phẩm',
        'image': 'assets/image/banner1.png',
      },
      {
        'title': 'BỘ SƯU TẬP MỚI',
        'subtitle': 'Thời trang xu hướng 2024',
        'image': 'assets/image/banner1.png',
      },
      {
        'title': 'MIỄN PHÍ SHIP',
        'subtitle': 'Đơn hàng từ 500k',
        'image': 'assets/image/banner1.png',
      },
    ];

    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(banner['image']!, fit: BoxFit.cover),
              );
            },
          ),
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: banners.asMap().entries.map((entry) {
                return Container(
                  width: _currentBannerIndex == entry.key ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentBannerIndex == entry.key
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category.id == _selectedCategoryId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryId = category.id;
                _filterProducts();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 0, 0, 0)
                    : const Color.fromARGB(255, 216, 216, 216),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: isSelected
                      ? const Color.fromARGB(255, 255, 255, 255)
                      : const Color.fromARGB(221, 0, 0, 0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPriceRangeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Khoảng giá',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          RangeSlider(
            values: _currentRangeValues,
            min: 0,
            max: 3000000,
            divisions: 100,
            labels: RangeLabels(
              _currentRangeValues.start.round().toString(),
              _currentRangeValues.end.round().toString(),
            ),
            onChanged: (values) {
              setState(() {
                _currentRangeValues = values;
                _filterProducts();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // giữ nguyên như bạn gửi
    final isOutOfStock = product.stock == 0;
    return Card(
      // ... không thay đổi
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  ProductDetailScreen(product: product, categoryName: ''),
            ),
          );
          if (result == true || result == 'refresh') {
            _fetchData();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 220,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${product.price.toStringAsFixed(0)} ₫',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isOutOfStock ? 'Hết hàng' : 'Còn hàng',
                    style: TextStyle(
                      fontSize: 15,
                      color: isOutOfStock ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      // Freeship và COD badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(20, 39, 174, 96),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color.fromARGB(255, 39, 174, 96),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 14,
                              color: Color.fromARGB(255, 39, 174, 96),
                            ),
                            SizedBox(width: 2),
                            Text(
                              "Freeship",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color.fromARGB(255, 39, 174, 96),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(20, 243, 156, 18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color.fromARGB(255, 243, 156, 18),
                          ),
                        ),
                        child: const Text(
                          "COD",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color.fromARGB(255, 243, 156, 18),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "⭐ 4.8 | Đã bán 1.2k",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color.fromARGB(255, 26, 26, 26),
                    ),
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
