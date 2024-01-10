import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:dio/dio.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_html/flutter_html.dart';

var dio = Dio();

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<dynamic> productDetail;
  // late Future<void> productContent;
  final CarouselController _controller = CarouselController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    productDetail = getProductDetail();
    // productContent = getProductContent();
  }

  Future<dynamic> getProductDetail() async {
    try {
      var response =
          await dio.get('${demo_url}/api/product/detail/${widget.productId}');
      // print(widget.productId);
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to load product detail');
      }
    } catch (e) {
      throw Exception('Failed to load product detail');
    }
  }

  // Future<void> getProductContent() async {
  //   try {
  //     final response =
  //         await dio.get('${demo_url}/product/content/${widget.productId}');
  //     if (response.statusCode == 200) {
  //       // 假設response.data就是您需要的字符串
  //       return response.data;
  //     } else {
  //       throw Exception('Failed to load product content');
  //     }
  //   } catch (e) {
  //     throw Exception('Failed to load product content: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('產品明細'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<dynamic>(
        future: productDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              var product = snapshot.data;
              var productDescription = '';
              print(product['description']);
              // if (product['description'] != null) {
              //   productDescription = product['description'];
              // }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    CarouselSlider(
                      carouselController: _controller,
                      options: CarouselOptions(
                        height: 300.0,
                        enlargeCenterPage: false,
                        autoPlay: true,
                        autoPlayInterval: const Duration(seconds: 3),
                        autoPlayAnimationDuration:
                            const Duration(milliseconds: 800),
                        autoPlayCurve: Curves.fastOutSlowIn,
                        pauseAutoPlayOnTouch: true,
                        aspectRatio: 2.0,
                        viewportFraction: 1.0,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _current = index; // 更新_index以使點點指示器同步
                          });
                        },
                      ),
                      items: product['images'].map<Widget>((item) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Image.network(item,
                                fit: BoxFit.cover,
                                width: MediaQuery.of(context).size.width);
                          },
                        );
                      }).toList(),
                    ),
                    buildIndicator(
                      _current,
                      product['images'].length,
                    ),
                    Text(product['name'],
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    // HtmlWidget(product['description']),

                    Text(product['description']),
                    Text('數量: ${product['quantity']}'),
                    Text('價格: ${product['price']}'),
                    // Add more fields as needed
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
          }
          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget buildIndicator(int currentIndex, int itemCount) {
    print(itemCount);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index
                ? Theme.of(context).primaryColor // Active color
                : Colors.grey.shade400, // Inactive color
          ),
        ),
      ),
    );
  }
}
