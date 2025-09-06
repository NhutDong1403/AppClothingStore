class ProductVariant {
  final String id; // Hoặc productID hoặc variantID
  final String size;
  final String color;
  final int stock;

  ProductVariant({
    required this.id,
    required this.size,
    required this.color,
    required this.stock,
  });

  ProductVariant copyWith({
    String? id,
    String? size,
    String? color,
    int? stock,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      size: size ?? this.size,
      color: color ?? this.color,
      stock: stock ?? this.stock,
    );
  }

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['productId'].toString(),
      size: json['size'].toString(),
      color: json['color'].toString(),
      stock: json['stock'] is int
          ? json['stock']
          : int.tryParse(json['stock'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'size': size,
    'color': color,
    'stock': stock,
  };

  bool isValid() {
    return id.isNotEmpty && size.isNotEmpty && color.isNotEmpty && stock >= 0;
  }
}
