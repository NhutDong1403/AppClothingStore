class OrderDetail {
  final int id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;

  OrderDetail({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final productIdRaw = json['productId'];
    if (productIdRaw == null) {
      throw Exception('productId không được null');
    }

    return OrderDetail(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['orderId'].toString(),
      productId: productIdRaw.toString(),
      quantity: int.tryParse(json['quantity'].toString()) ?? 0,
      unitPrice: double.tryParse(json['unitPrice'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  double get totalPrice => quantity * unitPrice;
}
