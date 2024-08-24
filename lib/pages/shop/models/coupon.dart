class Coupon {
  final String couponId;
  final String name;
  final String code;
  final String type;
  final String discount;
  final String total;
  final String status;

  Coupon({
    required this.couponId,
    required this.name,
    required this.code,
    required this.type,
    required this.discount,
    required this.total,
    required this.status,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      couponId: json['coupon_id'],
      name: json['name'],
      code: json['code'],
      type: json['type'],
      discount: json['discount'],
      total: json['total'],
      status: json['status'],
    );
  }
}
