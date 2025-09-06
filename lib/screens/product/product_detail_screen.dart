import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../../providers/product_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final String categoryName;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.categoryName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  String? _selectedSize;
  String? _selectedColor;
  int? _selectedVariantStock;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final product =
        context.watch<ProductProvider>().getProductById(widget.product.id.toString()) ??
        widget.product;

    final isOutOfStock = product.stock == 0;

    final availableSizes = product.variants.map((v) => v.size).toSet().toList();

    final availableColors = product.variants
        .map((v) => v.color)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          product.name.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 28,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Hero(
              tag: product.imageUrl,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade100, Colors.blue.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    product.imageUrl,
                    height: screenHeight * 0.4,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 70),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 10,
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'BebasNeue',
                          color: Colors.black87,
                          letterSpacing: 1.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.categoryName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '${product.price.toStringAsFixed(0)}đ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildSizeDropdown(availableSizes),
                      const SizedBox(height: 16),
                      _buildColorDropdown(product, availableColors),
                      const SizedBox(height: 24),
                      _buildQuantitySelector(product),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: isOutOfStock
                ? null
                : () {
                    if (_selectedSize == null || _selectedColor == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng chọn kích cỡ và màu sắc'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                    _handleAddToCart(product);
                  },
            icon: const Icon(Icons.add_shopping_cart),
            label: Text(
              isOutOfStock ? 'HẾT HÀNG' : 'THÊM VÀO GIỎ',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isOutOfStock
                  ? Colors.grey
                  : Colors.blue.shade700,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSizeDropdown(List<String> sizes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Chọn kích cỡ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          value: _selectedSize,
          items: sizes
              .map((size) => DropdownMenuItem(value: size, child: Text(size)))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedSize = value;
              _selectedColor = null;
              _selectedVariantStock = null;
              _quantity = 1;
            });
          },
        ),
        const SizedBox(height: 8),
        if (_selectedSize != null)
          Builder(
            builder: (context) {
              final stockBySize = widget.product.variants
                  .where((v) => v.size == _selectedSize)
                  .fold<int>(0, (sum, v) => sum + v.stock);

              return Text(
                'Tồn kho:  $stockBySize',
                style: TextStyle(
                  color: stockBySize > 0 ? Colors.green.shade700 : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildColorDropdown(Product product, List<String> colors) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Chọn màu sắc',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: _selectedColor,
      items: colors
          .map((color) => DropdownMenuItem(value: color, child: Text(color)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedColor = value;

          if (_selectedSize == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vui lòng chọn kích cỡ trước khi chọn màu sắc'),
                backgroundColor: Colors.orange,
              ),
            );
            _selectedColor = null;
            return;
          }

          final variant = product.variants.firstWhere(
            (v) => v.size == _selectedSize && v.color == value,
          );

          _selectedVariantStock = variant.stock;
          _quantity = 1;
        });
      },
    );
  }

  Widget _buildQuantitySelector(Product product) {
    final maxStock = _selectedVariantStock ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
          icon: const Icon(Icons.remove),
          color: Colors.white,
          style: IconButton.styleFrom(backgroundColor: Colors.blue.shade600),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '$_quantity',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        IconButton.filled(
          onPressed: (_selectedVariantStock != null && _quantity < maxStock)
              ? () => setState(() => _quantity++)
              : null,
          icon: const Icon(Icons.add),
          color: Colors.white,
          style: IconButton.styleFrom(backgroundColor: Colors.blue.shade600),
        ),
      ],
    );
  }

  void _handleAddToCart(Product product) {
    if (_selectedVariantStock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn kích cỡ và màu sắc'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_quantity > _selectedVariantStock!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số lượng tồn kho không đủ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cartService = Provider.of<CartService>(context, listen: false);

    cartService.addToCart(
      CartItem(
        productId: product.id,
        productName: product.name,
        price: product.price,
        imageUrl: product.imageUrl,
        quantity: _quantity,
        size: _selectedSize!,
        color: _selectedColor!,
      ),
    );

    final updatedVariants = product.variants.map((v) {
      if (v.size == _selectedSize && v.color == _selectedColor) {
        return v.copyWith(stock: v.stock - _quantity);
      }
      return v;
    }).toList();

    final updatedProduct = product.copyWith(variants: updatedVariants);

    Provider.of<ProductProvider>(
      context,
      listen: false,
    ).updateProduct(updatedProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 8),
            Text("Đã thêm vào giỏ hàng"),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );

    Navigator.pop(context, 'refresh');
  }
}
