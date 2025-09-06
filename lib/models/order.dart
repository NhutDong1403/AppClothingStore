import 'package:flutter/foundation.dart';
import 'cart_item.dart';

class Order {
  final int id;
  final int? userId;
  final List<CartItem> items;
  final double totalAmount;
  final double discountAmount;
  final DateTime orderDate;
  final String status;
  final String receiverName;
  final String phone;
  final String address;
  final String note;
  final String? voucherCode;
  final String paymentMethod;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    required this.receiverName,
    required this.phone,
    required this.address,
    required this.note,
    this.voucherCode,
    required this.paymentMethod,
    this.discountAmount = 0,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    debugPrint("📥 [Order.fromJson] Raw JSON: $json");

    return Order(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,

      userId: json['userId'] == null
          ? null
          : (json['userId'] is int
              ? json['userId']
              : int.tryParse(json['userId'].toString()) ?? 0),

      items: (json['orderDetails'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromJson(item))
          .toList(),

      totalAmount: (json['totalAmount'] is int)
          ? (json['totalAmount'] as int).toDouble()
          : (json['totalAmount'] as num?)?.toDouble() ?? 0.0,

      discountAmount: (json['discountAmount'] is int)
          ? (json['discountAmount'] as int).toDouble()
          : (json['discountAmount'] as num?)?.toDouble() ?? 0.0,

      orderDate: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),

      status: json['status']?.toString() ?? '',
      receiverName: json['receiverName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      voucherCode: json['voucherCode']?.toString(),
      paymentMethod: json['paymentMethod']?.toString() ?? 'cod',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'createdAt': orderDate.toIso8601String(),
      'receiverName': receiverName,
      'phone': phone,
      'address': address,
      'note': note,
      'paymentMethod': paymentMethod,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'status': status,
    };

    if (userId != null) {
      map['userId'] = userId;
    }
    if (voucherCode != null && voucherCode!.isNotEmpty) {
      map['voucherCode'] = voucherCode;
    }

    debugPrint("📤 [Order.toJson] Data: $map");

    return map;
  }

  String get voucherDescription {
    if (voucherCode == null || voucherCode!.isEmpty) return '';
    return 'Mã giảm giá: $voucherCode';
  }

  Order copyWith({
    int? id,
    int? userId,
    List<CartItem>? items,
    double? totalAmount,
    double? discountAmount,
    DateTime? orderDate,
    String? status,
    String? receiverName,
    String? phone,
    String? address,
    String? note,
    String? voucherCode,
    String? paymentMethod,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      receiverName: receiverName ?? this.receiverName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      note: note ?? this.note,
      voucherCode: voucherCode ?? this.voucherCode,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
