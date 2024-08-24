class ShippingMethod {
  String title;
  int cost;
  String code;
  bool error;
  int? sortOrder;

  ShippingMethod({
    required this.title,
    required this.code,
    required this.cost,
    required this.error,
    required this.sortOrder,
  });

  factory ShippingMethod.fromJson(Map<String, dynamic> json) {
    var sortOrderString = json['sort_order']?.toString();
    int? sortOrder = int.tryParse(sortOrderString ?? '0');

    var costString = json['cost']?.toString();
    int cost = int.tryParse(costString ?? '0') ?? 0;

    return ShippingMethod(
      title: json['title'],
      code: json['code'],
      cost: cost,
      error: json['error'],
      sortOrder: sortOrder ?? 0,
    );
  }
}
