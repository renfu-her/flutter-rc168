import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:rc168/responsive_text.dart';
import 'package:text_responsive/text_responsive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:flutter_responsive_framework/flutter_responsive_framework.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<dynamic> productDetail;
  Map<String, String> selectedOptionValues = {};
  // late Future<void> productContent;
  final CarouselController _controller = CarouselController();
  int _current = 0;
  int _selectedQuantity = 1;
  List service = [];

  @override
  void initState() {
    super.initState();
    productDetail = getProductDetail().then((data) {
      var options = data['options'] as List<ProductOption>;
      for (var option in options) {
        if (option.values.isNotEmpty) {
          // 為每個選項設置預設值，如果已經有值則不覆蓋
          selectedOptionValues[option.id] =
              selectedOptionValues[option.id] ?? option.values.first.id;
        }
      }
      return data;
    });
  }

  String convertHtmlToString(String htmlContent) {
    var document = html_parser.parse(htmlContent);

    // Format headings
    document.querySelectorAll('h1, h2, h3, h4, h5, h6').forEach((element) {
      element.replaceWith(dom.Text('${element.text}\n'));
    });

    // Format paragraphs
    document.querySelectorAll('p').forEach((element) {
      element.replaceWith(dom.Text(
          '${element.text}\n\n')); // Added an extra newline for paragraph spacing
    });

    // Replace 'li' with bullet points
    document.querySelectorAll('li').forEach((element) {
      element.replaceWith(dom.Text('• ${element.text}\n'));
    });

    // Extract 'src' from 'img' tags and include it in the text
    document.querySelectorAll('img').forEach((element) {
      var imgSrc = element.attributes['src'];
      if (imgSrc != null) {
        // This will insert the URL text directly into the output.
        // You may want to format it or handle it differently depending on your needs.
        element.replaceWith(dom.Text('Image: $imgSrc\n'));
      }
    });

    return document.body!.text
        .trim(); // Trim to remove any leading/trailing whitespace
  }

  Future<dynamic> getProductDetail() async {
    try {
      var response =
          await dio.get('${demoUrl}/api/product/detail/${widget.productId}');
      // print(widget.productId);
      if (response.statusCode == 200) {
        var productOptions = response.data['data']['options'] as List;
        var productOptionsParsed =
            productOptions.map((json) => ProductOption.fromJson(json)).toList();

        // print(response.data['data']);
        return {
          'details': response.data['data'],
          'options': productOptionsParsed,
        };
      } else {
        throw Exception('Failed to load product detail');
      }
    } catch (e) {
      throw Exception('Failed to load product detail');
    }
  }

  String splitByLengthAndJoin(String str, int length,
      {String separator = ' '}) {
    List<String> parts = [];
    for (int i = 0; i < str.length; i += length) {
      int end = (i + length < str.length) ? i + length : str.length;
      parts.add(str.substring(i, end));
    }
    return parts.join(separator);
  }

  Future<Map<String, dynamic>> fetchCustomerServiceData(int number) async {
    var dio = Dio();
    Map<String, dynamic> service = {};
    try {
      var response = await dio.get(
          '${appUri}/gws_appservice/onlineCustomerService&api_key=${apiKey}');
      if (response.statusCode == 200) {
        var data = response.data;
        if (data['status'] == 0 || data['status'] == null) {
          // 根据number选择返回哪个服务信息
          service = data[number == 1
              ? 'online_customer_service_1'
              : 'online_customer_service_2'];
        } else {
          print('Status is not 0 or null.');
        }
      } else {
        print('Failed to fetch data: HTTP status ${response.statusCode}');
      }
    } on DioError catch (e) {
      print('Dio error: ${e.message}');
    } catch (e) {
      print('Error: $e');
    }
    return service;
  }

  // TODO: 加入分享功能
  void showShareDialog(BuildContext context) async {
    Map<String, dynamic> fetchData1 = await fetchCustomerServiceData(1);
    Map<String, dynamic> fetchData2 = await fetchCustomerServiceData(2);
    print(fetchData1);
    print(fetchData2);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)), // Rounded corners
          child: Container(
            padding: EdgeInsets.all(20.0),
            height: 120, // Set the height of the dialog
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceEvenly, // Center the icons horizontally
                  children: <Widget>[
                    if (fetchData1['status'] == '1')
                      IconButton(
                        icon: Image.network(
                          fetchData1['thumb'],
                          width: 40,
                          height: 40,
                        ),
                        color: Colors.green, // Icon size
                        onPressed: () async {
                          // Line sharing code
                          Share.share(fetchData1['link'], subject: 'LINE 通知');
                          // Navigator.of(context).pop();
                        },
                      ),
                    if (fetchData2['status'] == '1')
                      IconButton(
                        icon: Image.network(
                          fetchData2['thumb'],
                          width: 40,
                          height: 40,
                        ),
                        color: Colors.blue, // Icon size
                        onPressed: () async {
                          // Messenger sharing code
                          Share.share(fetchData2['link'],
                              subject: 'FaceBook 通知');
                          // Navigator.of(context).pop();
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
        actions: [
          IconButton(icon: Icon(FontAwesomeIcons.heart), onPressed: () {}),
          IconButton(
              icon: Icon(FontAwesomeIcons.headset),
              onPressed: () {
                showShareDialog(context);
              }),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: productDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              var product = snapshot.data['details'];
              var options = snapshot.data['options'] as List<ProductOption>;

              List<Widget> contentWidgets = [];

              if (options.isNotEmpty) {
                contentWidgets.add(
                  const Center(
                      child: InlineTextWidget(
                    '款式及尺寸',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )),
                );
              }

              List<Widget> optionWidgets = options.map((option) {
                return ListTile(
                  title: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: InlineTextWidget(option.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        flex: 3,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            hint: const Text('請選擇'),
                            isExpanded: true,
                            value: selectedOptionValues[option.id],
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  selectedOptionValues[option.id] = newValue;
                                }
                              });
                            },
                            items: option.values.map((OptionValue value) {
                              return DropdownMenuItem<String>(
                                value: value.id,
                                child: value.price == 0
                                    ? ResponsiveText("${value.name}",
                                        baseFontSize: 34)
                                    : ResponsiveText(
                                        "${value.name}(${value.pricePrefix}NT\$${value.price.toString()})",
                                        baseFontSize: 34),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();

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
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                ResponsiveText(product['name'],
                                    baseFontSize: 40,
                                    fontWeight: FontWeight.bold),
                                product['special'] == false
                                    ? Column(children: [
                                        ResponsiveText("",
                                            baseFontSize: 28,
                                            textAlign: TextAlign.center,
                                            decoration:
                                                TextDecoration.lineThrough,
                                            color: Colors.grey),
                                        ResponsiveText(
                                          'NT' + product['price'],
                                          baseFontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          textAlign: TextAlign.center,
                                          color: Colors.red,
                                        )
                                      ])
                                    : Column(
                                        children: [
                                          ResponsiveText(
                                              'NT' + product['price'],
                                              baseFontSize: 28,
                                              textAlign: TextAlign.center,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey),
                                          ResponsiveText(
                                            'NT' + product['special'],
                                            baseFontSize: 36,
                                            textAlign: TextAlign.center,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              // IconButton(
                              //   icon: const Icon(Icons.share), // 使用分享图标
                              //   onPressed: () {
                              //     Share.share('商品: ${product['name']}');
                              //   },
                              // ),
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
                                          : Colors.red), // 文本顏色也可以相應改變
                                ),
                              ),
                              const SizedBox(height: 6),
                              QuantitySelector(
                                quantity: _selectedQuantity,
                                onQuantityChanged: (newQuantity) {
                                  setState(() {
                                    _selectedQuantity = newQuantity;
                                  });
                                },
                              ), // 自定義的數量選擇器小部件
                            ],
                          ),
                        ],
                      ),
                    ),
                    ...contentWidgets,
                    ...optionWidgets,
                    const SizedBox(height: 6),
                    const Center(
                      child: InlineTextWidget(
                        '商品描述',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20),
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
                                MyHtmlWidget(
                                  htmlContent: '<h1>測試商品01</h1><h1>測試測試測試</h1><img src="https://ocapi.remember1688.com/image/catalog/%E7%94%A2%E5%93%81%E5%9C%96/WeChat%20%E6%88%AA%E5%9C%96_20240210230805.png" >' +
                                      '<p></p><h1>測試商品02</h1><h1>測試測試測試</h1><img src="https://ocapi.remember1688.com/image/catalog/%E7%94%A2%E5%93%81%E5%9C%96/WeChat%20%E6%88%AA%E5%9C%96_20240105141314.png" >' +
                                      '<p></p><h1>測試商品03</h1><h1>測試測試測試</h1><img src="https://ocapi.remember1688.com/image/catalog/%E7%94%A2%E5%93%81%E5%9C%96/ST10PRO.png">' +
                                      '<h1>測試商品01</h1><h1>測試測試測試</h1><img src="https://ocapi.remember1688.com/image/catalog/%E7%94%A2%E5%93%81%E5%9C%96/WeChat%20%E6%88%AA%E5%9C%96_20240210230805.png" >' +
                                      '<p></p><h1>測試商品02</h1><h1>測試測試測試</h1><img src="https://ocapi.remember1688.com/image/catalog/%E7%94%A2%E5%93%81%E5%9C%96/WeChat%20%E6%88%AA%E5%9C%96_20240105141314.png" >' +
                                      '<p></p><h1>測試商品03</h1><h1>測試測試測試</h1><img src="https://ocapi.remember1688.com/image/catalog/%E7%94%A2%E5%93%81%E5%9C%96/ST10PRO.png" >',
                                  baseFontSize: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
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
            onPressed: () async {
              if (isLogin == true) {
                await addToCart(widget.productId, _selectedQuantity);
                selectedIndex = 3;
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => MyApp()));
              } else {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: ResponsiveText(
                        '您尚未登入會員 ',
                        baseFontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: <Widget>[
                            ResponsiveText(
                              '請先登入會員！',
                              baseFontSize: 36,
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('取消'),
                          onPressed: () {
                            Navigator.of(context).pop(); // 关闭对话框
                          },
                        ),
                        TextButton(
                          child: Text('登入'),
                          onPressed: () {
                            // 可以在这里添加跳转到登录页面的代码
                            Navigator.of(context).pop(); // 先关闭对话框
                            // 假设你有一个名为LoginPage的登录页面
                            selectedIndex = 4;
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => MyApp()));
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
            child: InlineTextWidget('加入購物車',
                style: TextStyle(fontSize: 18, color: Colors.white)),
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

List<Widget> convertHtmlToWidgets(String htmlContent,
    {double baseFontSize = 14}) {
  var document = html_parser.parse(htmlContent);
  List<Widget> widgetsList = [];

  document.body!.nodes.forEach((node) {
    if (node is dom.Element) {
      switch (node.localName) {
        case 'h1':
          widgetsList.add(Text(node.text,
              style: TextStyle(
                  fontSize: baseFontSize, fontWeight: FontWeight.bold)));
          break;
        case 'p':
          widgetsList
              .add(Text(node.text, style: TextStyle(fontSize: baseFontSize)));
          break;
        case 'img':
          var imgSrc = node.attributes['src'];
          if (imgSrc != null) {
            widgetsList.add(Image.network(
              imgSrc,
              width: double.infinity, // Set width to screen width
            ));
          }
          break;
        // ... Handle other HTML tags
      }
    } else if (node is dom.Text) {
      widgetsList
          .add(Text(node.text, style: TextStyle(fontSize: baseFontSize)));
    }
  });

  return widgetsList;
}

class MyHtmlWidget extends StatelessWidget {
  final String htmlContent;
  final double baseFontSize;

  MyHtmlWidget({Key? key, required this.htmlContent, this.baseFontSize = 14})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets =
        convertHtmlToWidgets(htmlContent, baseFontSize: baseFontSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class QuantitySelector extends StatefulWidget {
  final int quantity;
  final Function(int) onQuantityChanged;

  const QuantitySelector(
      {Key? key, required this.quantity, required this.onQuantityChanged})
      : super(key: key);

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
      widget.onQuantityChanged(currentQuantity);
    });
  }

  void decrementQuantity() {
    if (currentQuantity > 1) {
      setState(() {
        currentQuantity--;
        widget.onQuantityChanged(currentQuantity);
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
                    fontSize: 16,
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

Future<void> addToCart(String productId, int quantity) async {
  final formData = FormData.fromMap({
    'product_id': productId,
    'quantity': quantity,
  });

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

// 這是從API響應解析選項的模型
class ProductOption {
  final String id;
  final String name;
  final List<OptionValue> values;

  ProductOption({required this.id, required this.name, required this.values});

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    var list = json['product_option_value'] as List;
    List<OptionValue> optionValues =
        list.map((i) => OptionValue.fromJson(i)).toList();

    return ProductOption(
      id: json['product_option_id'],
      name: json['name'],
      values: optionValues,
    );
  }
}

// 這是單個選項值的模型
class OptionValue {
  final String id;
  final String name;
  final int price;
  final String pricePrefix;
  final String priceName;

  OptionValue(
      {required this.id,
      required this.name,
      required this.price,
      required this.pricePrefix,
      required this.priceName});

  factory OptionValue.fromJson(Map<String, dynamic> json) {
    double priceDouble = double.tryParse(json['price']) ?? 0.0;
    int priceInt = (priceDouble).toInt();

    String priceName = priceInt == 0 ? '' : "NTD${priceInt.toString()}";

    return OptionValue(
      id: json['product_option_value_id'],
      name: json['name'],
      price: priceInt,
      pricePrefix: json['price_prefix'],
      priceName: priceName,
    );
  }
}
