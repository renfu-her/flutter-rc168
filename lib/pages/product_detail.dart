import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

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

  String convertHtmlToString(String htmlContent) {
    var document = html_parser.parse(htmlContent);

    document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach((element) {
      element.replaceWith(dom.Text('${element.text}\n'));
    });

    document.querySelectorAll('p').forEach((element) {
      element.replaceWith(dom.Text('${element.text}\n'));
    });
    // // 将li标签替换为点
    document.querySelectorAll('li').forEach((element) {
      element.replaceWith(dom.Text('• ${element.text}\n'));
    });

    return document.body!.text;
  }

  Future<dynamic> getProductDetail() async {
    try {
      var response =
          await dio.get('${demoUrl}/api/product/detail/${widget.productId}');
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

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Image carousel slider
                    CarouselSlider(
                      carouselController: _controller,
                      options: CarouselOptions(
                        height: 320.0,
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
                    buildIndicator(_current, product['images'].length),

                    // Product details layout
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['name'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                Center(
                                  // 将Text包裹在Center小部件中以实现居中对齐
                                  child: Text('NT${product['price']}',
                                      style: const TextStyle(
                                          fontSize: 18, color: Colors.red)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.share), // 使用分享图标
                                onPressed: () {
                                  Share.share('商品: ${product['name']}');
                                },
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5.0,
                                    horizontal: 8.0), // 調整文本周圍的空間
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: product['stock_status'] == '有現貨'
                                        ? Colors.green
                                        : Colors.red, // 根據庫存狀態設定邊框顏色
                                    width: 1.0, // 邊框寬度
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(5.0), // 邊框圓角
                                ),
                                child: Text(
                                  product['stock_status'],
                                  style: TextStyle(
                                    color: product['stock_status'] == '有現貨'
                                        ? Colors.green
                                        : Colors.red, // 文本顏色也可以相應改變
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const QuantitySelector(
                                  quantity: 1), // 自定義的數量選擇器小部件
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    convertHtmlToString(product['description']),
                                    style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue, // 设定背景颜色
                                borderRadius:
                                    BorderRadius.circular(6.0), // 这里设置圆角大小
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RatingStarWidget(rating: product['rating'])
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 160),
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
      bottomSheet: Container(
        color: Colors.white,
        width: double.infinity, // 容器宽度占满整个屏幕宽度
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: ElevatedButton(
            onPressed: () {},
            child: Text(
              '加入購物車',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // 按钮背景颜色为蓝色
              foregroundColor: Colors.white, // 文本颜色为白色
              minimumSize: Size(double.infinity, 36), // 按钮最小尺寸，宽度占满
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6), // 圆角矩形按钮
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildIndicator(int currentIndex, int itemCount) {
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

class QuantitySelector extends StatefulWidget {
  final int quantity;
  const QuantitySelector({Key? key, required this.quantity}) : super(key: key);

  @override
  _QuantitySelectorState createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  int currentQuantity = 0;

  @override
  void initState() {
    super.initState();
    currentQuantity = widget.quantity;
  }

  void incrementQuantity() {
    setState(() {
      currentQuantity++;
    });
  }

  void decrementQuantity() {
    if (currentQuantity > 1) {
      setState(() {
        currentQuantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey), // 設置邊框顏色
            borderRadius: BorderRadius.circular(4.0), // 設置邊框圓角
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max, // 將Row的大小限制為子元素所需的最小大小
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: Colors.black),
                onPressed: decrementQuantity,
                constraints: BoxConstraints(
                  // 限制IconButton的大小
                  minWidth: 32.0, // 最小寬度
                  minHeight: 32.0, // 最小高度
                ),
                padding: EdgeInsets.zero, // 移除內部填充
              ),
              Container(
                color: Colors.grey[200], // 數量部分的背景顏色
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 4.0), // 數量部分的填充
                child: Text(
                  '$currentQuantity', // 顯示當前數量
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.black),
                onPressed: incrementQuantity,
                constraints: BoxConstraints(
                  // 限制IconButton的大小
                  minWidth: 32.0, // 最小寬度
                  minHeight: 32.0, // 最小高度
                ),
                padding: EdgeInsets.zero, // 移除內部填充
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Example of a rating star widget
class RatingStarWidget extends StatelessWidget {
  final int rating;
  final double size; // 新增一個size參數來控制星星的大小

  const RatingStarWidget({
    Key? key,
    required this.rating,
    this.size = 40.0, // 設定一個默認值，比如40.0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> stars = List.generate(5, (index) {
      return Icon(
        index < rating ? Icons.star : Icons.star_border,
        color: Colors.amber,
        size: size, // 使用傳入的size參數來設定星星大小
      );
    });

    return Row(children: stars);
  }
}
