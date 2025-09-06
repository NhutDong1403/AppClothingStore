class Voucher {
  final int id;
  final String code;
  final String description;
  final String discount;
  final bool isActive;
  final String createdAt;

  Voucher({
    required this.id,
    required this.code,
    required this.description,
    required this.discount,
    required this.isActive,
    required this.createdAt,
  });
  Voucher copyWith({
    int? id,
    String? code,
    String? description,
    String? discount,
    bool? isActive,
    String? createdAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      description: description ?? this.description,
      discount: discount ?? this.discount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'],
    code: json['code'],
    description: json['description'] ?? '',
    discount: json['discount'],
    isActive: json['isActive'],
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'description': description,
    'discount': discount,
    'isActive': isActive,
    'createdAt': createdAt, // ✅ Bắt buộc
  };
}
