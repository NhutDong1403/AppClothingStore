import 'package:appbanquanao/models/product_variant.dart';

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int categoryId;
  final List<ProductVariant> variants;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.variants,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      stock: json['stock'] ?? 0,
      variants: (json['variants'] as List<dynamic>? ?? [])
          .map((v) => ProductVariant.fromJson(v))
          .toList(),
    );
  }

  Map<String, dynamic> toJson({bool includeId = false}) {
    final map = {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'variants': variants.map((v) => v.toJson()).toList(),
    };
    if (includeId) map['id'] = id;
    return map;
  }

  int get totalStock => variants.fold(0, (sum, v) => sum + v.stock);

  bool isValid() {
    return name.isNotEmpty &&
        description.isNotEmpty &&
        price > 0 &&
        categoryId > 0 &&
        imageUrl.isNotEmpty &&
        variants.isNotEmpty &&
        variants.every((v) => v.isValid());
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    int? categoryId,
    List<ProductVariant>? variants,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      variants: variants ?? this.variants,
      stock: stock ?? this.stock,
    );
  }
}
