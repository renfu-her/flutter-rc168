import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/product_detail.dart';
import 'package:url_launcher/url_launcher.dart';

var dio = Dio();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // 檢測屏幕寬度以決定欄位數
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    int crossAxisCount = screenWidth < 600 ? 2 : 4;
    PageController _controller = PageController(initialPage: 1000); // 初始頁面
    Timer? _timer;

    void _startAutoScroll() {
      _timer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
        if (_controller.hasClients) {
          int currentPage = _controller.page!.toInt();
          int nextPage = currentPage + 1;
          // print(nextPage);
          _controller.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      });
    }

    @override
    void initState() {
      super.initState();
      _startAutoScroll();
    }

    @override
    void dispose() {
      _timer?.cancel(); // 取消定時器
      _controller.dispose(); // 釋放控制器資源
      super.dispose();
    }

    // print(fetchBanners());
    return Scaffold(
      // appBar: AppBar(title: Text('最新商品')),
      body: Column(
        children: <Widget>[
          FutureBuilder<List<BannerModel>>(
            future: fetchBanners(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('No banners found');
              } else {
                return buildBannerCarousel(snapshot.data!);
              }
            },
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '最新商品',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: fetchProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: const Text("No products found"));
                } else {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.7,
                    ),
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
                                    '${img_url}' + product.thumb,
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
                              padding: EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.center, // 將對齊方式改為置中
                                children: <Widget>[
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center, // 文本對齊也設置為居中
                                  ),
                                  Text(
                                    product.price,
                                    textAlign: TextAlign.center, // 文本對齊設置為居中
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: ElevatedButton(
                                child: Text('加入購物車'),
                                onPressed: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //       builder: (context) => ProductDetailPage(
                                  //             productId: product.id,
                                  //           )),
                                  // );
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
          ),
        ],
      ),
    );
  }

  Widget buildBannerCarousel(List<BannerModel> banners) {
    // 創建一個PageController，initialPage設置為一個很大的數字
    PageController controller =
        PageController(initialPage: 1000 * banners.length);

    return Container(
      height: 200, // 設定輪播區域高度
      child: PageView.builder(
        controller: controller,
        itemCount: null, // 使itemCount為無限
        itemBuilder: (context, index) {
          // 使用餘數運算符來循環banners列表
          var actualIndex = index % banners.length;
          var banner = banners[actualIndex];
          return GestureDetector(
            onTap: () {
              _launchURL(banner.link);
            },
            child: Image.network(
              '${img_url}${banner.image}',
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  void _launchURL(String url) async {
    if (url.isNotEmpty && await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

Future<List<Product>> fetchProducts() async {
  try {
    var response = await Dio().get(
        '${app_url}/index.php?route=extension/module/api/gws_products_latest&api_key=${api_key}');
    return (response.data['latest_products'] as List)
        .map((p) => Product.fromJson(p))
        .toList();
  } catch (e) {
    print(e);
    throw e;
  }
}

Future<List<BannerModel>> fetchBanners() async {
  final response = await dio.get(
      '${app_url}/index.php?route=extension/module/api/gws_banner&banner_id=12&api_key=${api_key}');

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
