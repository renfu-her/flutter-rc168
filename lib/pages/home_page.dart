import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/product_detail.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';
// import 'package:rc168/pages/shop/shop_page.dart';
import 'package:rc168/responsive_text.dart';

var dio = Dio();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    // 檢測屏幕寬度以決定欄位數
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    int crossAxisCount = screenWidth < 600 ? 2 : 4;
    PageController _controller = PageController(initialPage: 1000); // 初始頁面

    Widget buildBannerCarousel(List<BannerModel> banners) {
      return CarouselSlider(
        options: CarouselOptions(
          height: 210.0,
          enlargeCenterPage: false,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 3),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          pauseAutoPlayOnTouch: true,
          aspectRatio: 2.0,
          viewportFraction: 1.0,
          // onPageChanged: (index, reason) {
          //   setState(() {
          //     _current = index; // 更新_index以使點點指示器同步
          //   });
          // },
        ),
        items: banners.map((banner) {
          return GestureDetector(
            onTap: () {
              _launchURL(banner.link);
            },
            child: Image.network(
              '${imgUrl}${banner.image}',
              fit: BoxFit.cover,
            ),
          );
        }).toList(),
      );
    }

    @override
    void initState() {
      super.initState();
    }

    @override
    void dispose() {
      super.dispose();
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            FutureBuilder<dynamic>(
              future: fetchBanners(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    var product = snapshot.data;
                    var images = product; // 确保这是字符串列表
                    return Column(
                      children: [
                        buildBannerCarousel(images),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return Text("Error: ${snapshot.error}");
                  }
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: ResponsiveText(
                '最新商品',
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign.center,
              ),
            ),
            FutureBuilder<List<Product>>(
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
                                        productId: product.id,
                                      ),
                                    ),
                                  );
                                },
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: Image.network(
                                    '${imgUrl}' + product.thumb,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                          child: CircularProgressIndicator());
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
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
                                  ResponsiveText(
                                    product.name,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center, // 文本對齊也設置為居中
                                  ),
                                  ResponsiveText(
                                    product.price,
                                    fontSize: 20,
                                    textAlign: TextAlign.center, // 文本對齊設置為居中
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                child: ResponsiveText(
                                  '加入購物車',
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailPage(
                                        productId: product.id,
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
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (url.isNotEmpty && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Could not launch');
    }
  }
}

Future<List<Product>> fetchProducts() async {
  try {
    var response =
        await Dio().get('${appUri}/gws_products_latest&api_key=${apiKey}');
    return (response.data['latest_products'] as List)
        .map((p) => Product.fromJson(p))
        .toList();
  } catch (e) {
    print(e);
    throw e;
  }
}

Future<List<BannerModel>> fetchBanners() async {
  final response =
      await dio.get('${appUri}/gws_banner&banner_id=12&api_key=${apiKey}');

  if (response.statusCode == 200) {
    List<dynamic> bannersJson = response.data['banner'];
    return bannersJson.map((json) => BannerModel.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load banners');
  }
}

class Product {
  final String id;
  final String name;
  final String thumb;
  final String price;

  Product(
      {required this.id,
      required this.name,
      required this.thumb,
      required this.price});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['product_id'],
      name: json['name'],
      thumb: json['thumb'],
      price: json['price'],
    );
  }
}

class BannerModel {
  final String bannerId;
  final String name;
  final String title;
  final String link;
  final String image;

  BannerModel(
      {required this.bannerId,
      required this.name,
      required this.title,
      required this.link,
      required this.image});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      bannerId: json['banner_id'],
      name: json['name'],
      title: json['title'],
      link: json['link'],
      image: json['image'],
    );
  }
}

Future<void> addToCart(String productId, int quantity) async {
  final formData = FormData.fromMap({
    'product_id': productId,
    'quantity': quantity,
  });

  print(productId);
  print(quantity);

  final addCartUrl =
      '${appUri}/gws_customer_cart/add&customer_id=${customerId}&api_key=${apiKey}';
  try {
    var response = await dio.post(
      addCartUrl,
      data: formData,
    );

    // 检查响应或进行后续操作
    if (response.data['message'][0]['msg_status'] == true) {
      // 成功添加后的操作
    }
  } on DioException catch (e) {
    // 错误处理
    print(e);
  }
}
