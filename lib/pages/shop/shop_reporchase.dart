import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/responsive_text.dart';
import 'package:rc168/pages/product_detail.dart';
import 'package:text_responsive/text_responsive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ShopRepurchasePage extends StatefulWidget {
  String orderId;
  ShopRepurchasePage({required this.orderId});

  @override
  _ShopRepurchasePageState createState() => _ShopRepurchasePageState();
}

class _ShopRepurchasePageState extends State<ShopRepurchasePage> {
  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<List<Product>> fetchProducts() async {
    Response response = await dio.get(
        '${appUri}/gws_appcustomer_order/info&customer_id=${customerId}&order_id=${widget.orderId}&&api_key=${apiKey}');
    if (response.statusCode == 200) {
      List<dynamic> data = response.data['products'];
      // print(data);
      return data.map((product) => Product.fromJson(product)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    int crossAxisCount = screenWidth < 600 ? 2 : 4;
    PageController _controller = PageController(initialPage: 1000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單詳情'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Product>>(
        future: fetchProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No products found"));
          } else {
            double totalPrice = 0;
            for (var product in snapshot.data!) {
              totalPrice += product.price * product.quantity;
            }

            return ListView.builder(
              itemCount: snapshot.data!.length + 1,
              itemBuilder: (context, index) {
                if (index < snapshot.data!.length) {
                  Product product = snapshot.data![index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // 移除圓角
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(
                              productId: product.productId,
                            ),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(8.0),
                        leading: Image.network(
                          product.image,
                          width: 100,
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
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '\$${product.price}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              'x ${product.quantity}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  return ListTile(
                    title: Text(
                      '總金額',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  );
                }
              },
            );
          }
        },
      ),
    );
  }
}

class Product {
  final String name;
  final String href;
  final String image;
  final String productId;
  final int price;
  final int quantity;

  Product({
    required this.name,
    required this.href,
    required this.image,
    required this.productId,
    required this.price,
    required this.quantity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 替换 href 中的 &amp; 为 &
    String href = json['href'] as String;
    href = href.replaceAll('&amp;', '&');

    // 提取 product_id 从 href 字段中
    final uri = Uri.parse(href);
    final productId = uri.queryParameters['product_id'] ?? '';

    // 去掉价格中的 $ 和 , 符号并转换为数字
    String priceString = json['price'] as String? ?? '';
    priceString = priceString.replaceAll('\$', '').replaceAll(',', '');
    int price = int.tryParse(priceString) ?? 0;

    // 将数量转换为整数
    int quantity = int.tryParse(json['quantity'] as String? ?? '') ?? 0;

    return Product(
      name: json['name'] as String? ?? '',
      href: href,
      image: json['image'] as String? ?? '',
      productId: productId,
      price: price,
      quantity: quantity,
    );
  }
}
