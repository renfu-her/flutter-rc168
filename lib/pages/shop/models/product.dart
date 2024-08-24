class Product {
  final String productId;
  final String name;
  final String thumbUrl;
  final int price;
  int quantity;
  final String cartId;
  final dynamic special;
  final List<Option> options;
  final List<Map<String, dynamic>> totals;

  Product({
    required this.productId,
    required this.name,
    required this.thumbUrl,
    required this.price,
    required this.quantity,
    required this.cartId,
    required this.special,
    required this.options,
    required this.totals,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      productId: json['product_id'],
      name: json['name'],
      thumbUrl: json['thumb'],
      price: int.parse(json['price'].replaceAll(RegExp(r'[^0-9\.]'), '')),
      quantity: int.parse(json['quantity']),
      cartId: json['cart_id'],
      special: json['special'] == false
          ? false
          : int.parse(json['special'].replaceAll(RegExp(r'[^0-9\.]'), '')),
      options:
          (json['options'] as List).map((e) => Option.fromJson(e)).toList(),
      totals: List<Map<String, dynamic>>.from(json['totals']),
    );
  }
}

class Option {
  final String productOptionId;
  final String productOptionValueId;
  final String type;
  final String value;
  final String name;

  Option({
    required this.productOptionId,
    required this.productOptionValueId,
    required this.type,
    required this.value,
    required this.name,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      productOptionId: json['product_option_id'],
      productOptionValueId: json['product_option_value_id'],
      type: json['type'],
      value: json['value'],
      name: json['name'],
    );
  }
}
