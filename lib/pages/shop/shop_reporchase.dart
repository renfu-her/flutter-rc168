import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/product_detail.dart';

class ShopRepurchasePage extends StatefulWidget {
  final String orderId;
  ShopRepurchasePage({required this.orderId});

  @override
  _ShopRepurchasePageState createState() => _ShopRepurchasePageState();
}

class _ShopRepurchasePageState extends State<ShopRepurchasePage> {
  late Future<OrderDetail> orderDetailFuture;

  @override
  void initState() {
    super.initState();
    orderDetailFuture = fetchOrderDetail();
  }

  Future<OrderDetail> fetchOrderDetail() async {
    Response response = await dio.get(
        '${appUri}/gws_appcustomer_order/info&customer_id=${customerId}&order_id=${widget.orderId}&&api_key=${apiKey}');
    if (response.statusCode == 200) {
      return OrderDetail.fromJson(response.data);
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單詳情'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4F4E4C),
      ),
      body: FutureBuilder<OrderDetail>(
        future: orderDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return const Center(child: Text("No data found"));
          } else {
            final order = snapshot.data!.order;
            final products = snapshot.data!.products;
            final histories = snapshot.data!.histories;
            final totals = snapshot.data!.totals;

            double totalPrice = 0;
            for (var product in products) {
              totalPrice += product.price * product.quantity;
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ...products.map((product) {
                  return Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.all(8.0),
                        leading: Image.network(
                          product.image,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                                child: CircularProgressIndicator());
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('規格: xxxxxx'),
                            Text('x ${product.quantity}'),
                          ],
                        ),
                        trailing: Text(
                          '\$${(product.price * product.quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                      ),
                      Divider(),
                    ],
                  );
                }).toList(),
                // const Text(
                //   'Order Histories:',
                //   style: const TextStyle(
                //       fontSize: 16, fontWeight: FontWeight.bold),
                // ),
                // ...histories.map((history) {
                //   return ListTile(
                //     title: Text(history.status),
                //     subtitle: Text(history.dateAdded),
                //   );
                // }).toList(),
                const ListTile(
                  title: Text(
                    '會員折扣(8%)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
                const ListTile(
                  title: Text(
                    '運費',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '\$60',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
                // ...totals.map((total) {
                //   return ListTile(
                //     title: Text(total.title),
                //     trailing: Text(total.text),
                //   );
                // }).toList(),
                ListTile(
                  title: const Text(
                    '訂單金額:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '\$${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}

class OrderDetail {
  final Order order;
  final List<Product> products;
  final List<History> histories;
  final List<Total> totals;

  OrderDetail({
    required this.order,
    required this.products,
    required this.histories,
    required this.totals,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      order: Order.fromJson(json['order'][0]),
      products:
          (json['products'] as List).map((i) => Product.fromJson(i)).toList(),
      histories:
          (json['histories'] as List).map((i) => History.fromJson(i)).toList(),
      totals: (json['totals'] as List).map((i) => Total.fromJson(i)).toList(),
    );
  }
}

class Order {
  final String orderId;
  final String firstname;
  final String lastname;
  final String total;

  Order({
    required this.orderId,
    required this.firstname,
    required this.lastname,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'] as String,
      firstname: json['firstname'] as String,
      lastname: json['lastname'] as String,
      total: json['total'] as String,
    );
  }
}

class Product {
  final String name;
  final String model;
  final String href;
  final String image;
  final String productId;
  final int price;
  final int quantity;

  Product({
    required this.name,
    required this.model,
    required this.href,
    required this.image,
    required this.productId,
    required this.price,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String href = json['href'] as String;
    href = href.replaceAll('&amp;', '&');

    final uri = Uri.parse(href);
    final productId = uri.queryParameters['product_id'] ?? '';

    String priceString = json['price'] as String? ?? '';
    priceString = priceString.replaceAll('\$', '').replaceAll(',', '');
    int price = int.tryParse(priceString) ?? 0;

    int quantity = int.tryParse(json['quantity'] as String? ?? '') ?? 0;

    return Product(
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      href: href,
      image: json['image'] as String? ?? '',
      productId: productId,
      price: price,
      quantity: quantity,
    );
  }
}

class History {
  final String dateAdded;
  final String status;

  History({
    required this.dateAdded,
    required this.status,
  });

  factory History.fromJson(Map<String, dynamic> json) {
    return History(
      dateAdded: json['date_added'] as String,
      status: json['status'] as String,
    );
  }
}

class Total {
  final String title;
  final String text;

  Total({
    required this.title,
    required this.text,
  });

  factory Total.fromJson(Map<String, dynamic> json) {
    return Total(
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
}
