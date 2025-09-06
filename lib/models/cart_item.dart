class CartItem {
  final int productId;
  final String productName;
  final double price;
  final String imageUrl;
  int quantity;
  final String color; // màu người dùng chọn
  final String size; // size người dùng chọn



  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.size,
    required this.color,
  });

  double get totalPrice => price * quantity;

  static int _parseId(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: _parseId(json['productId']),
      productName: json['productName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      quantity: json['quantity'] ?? 1,
      size: json['size']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId, // 🚀 giữ nguyên là int
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'size': size,
      'color': color,
    };
  }
}
