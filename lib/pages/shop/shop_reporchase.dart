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
        title: const Text('產品'),
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
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
              ),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Product product = snapshot.data![index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // 移除圓角
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: InkWell(
                          // 使用 InkWell 包裹圖片
                          onTap: () {
                            // 添加 onTap 事件
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  productId: product.productId,
                                ),
                              ),
                            );
                          },
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.error),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.center, // 將對齊方式改為置中
                          children: <Widget>[
                            InlineTextWidget(
                              product.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                            Column(children: [
                              ResponsiveText("",
                                  baseFontSize: 28,
                                  textAlign: TextAlign.center,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey),
                              ResponsiveText(
                                product.price,
                                baseFontSize: 36,
                                fontWeight: FontWeight.bold,
                                textAlign: TextAlign.center,
                              )
                            ])
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          child: InlineTextWidget(
                            '加入購物車',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                          onPressed: () async {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  productId: product.productId,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(6), // 設定圓角半徑為 10
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
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
  final String price;

  Product({
    required this.name,
    required this.href,
    required this.image,
    required this.productId,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 替換 href 中的 &amp; 為 &
    String href = json['href'] as String;
    href = href.replaceAll('&amp;', '&');

    // 提取 product_id 從 href 字段中
    final uri = Uri.parse(href);
    final productId = uri.queryParameters['product_id'] ?? '';

    return Product(
      name: json['name'] as String? ?? '',
      href: json['href'] as String? ?? '',
      image: json['image'] as String? ?? '',
      productId: productId,
      price: json['price'] as String? ?? '',
    );
  }
}
