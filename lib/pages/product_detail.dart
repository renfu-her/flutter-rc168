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
import 'package:url_launcher/url_launcher.dart';

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
  int stockStatus = 0;
  String? productName;
  bool isInWishlist = false;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    productDetail = getProductDetail().then((data) {
      var options = data['options'] as List<ProductOption>;
      for (var option in options) {
        if (option.values.isNotEmpty) {
          // Set default values for each option if not already set
          selectedOptionValues[option.id] =
              selectedOptionValues[option.id] ?? option.values.first.id;
        }
      }

      checkWishlistStatus();
      // stockStatus = data['details']['stock_status'] == '有現貨' ? 1 : 0;
      return data;
    });
  }

  Future<dynamic> getProductDetail() async {
    try {
      var response =
          await dio.get('${demoUrl}/api/product/detail/${widget.productId}');
      //// print{widget.productId);
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

  Future<void> checkWishlistStatus() async {
    try {
      var response = await dio.get(
        '${appUri}/gws_customer_wishlist&customer_id=${customerId}&api_key=${apiKey}',
      );

      print('${customerId}');

      if (response.statusCode == 200 &&
          response.data['message'][0]['msg_status']) {
        var wishlist = response.data['customer_wishlist'] as List;
        setState(() {
          isInWishlist =
              wishlist.any((item) => item['product_id'] == widget.productId);
        });
      }
    } catch (e) {
      print('Failed to load wishlist status: $e');
    }
  }

  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: ResponsiveText(
            title,
            baseFontSize: 36,
          ),
          content: ResponsiveText(
            message,
            baseFontSize: 30,
            maxLines: 5,
          ),
          actions: <Widget>[
            TextButton(
              child: ResponsiveText(
                '確定',
                baseFontSize: 36,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> addToWishlist() async {
    try {
      var response = await dio.get(
        '${appUri}/gws_customer_wishlist/add&customer_id=${customerId}&product_id=${widget.productId}&api_key=${apiKey}',
      );

      if (response.statusCode == 200 &&
          response.data['message'][0]['msg_status']) {
        setState(() {
          isInWishlist = true;
        });
        showNormalDialog(context, '願望清單', '已新增願望清單');
      }
    } catch (e) {
      print('Failed to add to wishlist: $e');
    }
  }

  Future<void> removeFromWishlist() async {
    try {
      var response = await dio.get(
        '${appUri}/gws_customer_wishlist/remove&customer_id=${customerId}&product_id=${widget.productId}&api_key=${apiKey}',
      );

      if (response.statusCode == 200 &&
          response.data['message'][0]['msg_status']) {
        setState(() {
          isInWishlist = false;
        });
        showNormalDialog(context, '願望清單', '已移除願望清單');
      }
    } catch (e) {
      print('Failed to remove from wishlist: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('產品明細'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4F4E4C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
              icon: Icon(
                isInWishlist
                    ? FontAwesomeIcons.solidHeart
                    : FontAwesomeIcons.heart,
                color: const Color(0xFFD72873),
              ),
              onPressed: () {
                isInWishlist ? removeFromWishlist() : addToWishlist();
              }),
          IconButton(
              icon: const Icon(FontAwesomeIcons.shareNodes),
              onPressed: () {
                displayShareDialog(context, productName!);
                // Share.share(
                //     "分享連接：https://social-plugins.line.me/lineit/share?url=https%3A%2F%2Focapi.remember1688.com%2F%2Findex.php%3Froute%3Dproduct%2Fproduct%26product_id%3D${widget.productId}");
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
              int quantity = int.tryParse(product['quantity']) ?? 0;
              int status = int.tryParse(product['status']) ?? 0;
              if (quantity > 0 && status > 0) {
                stockStatus = 1;
              } else {
                stockStatus = 0;
              }

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
                                    ? ResponsiveText(
                                        "${value.name}",
                                        baseFontSize: 34,
                                        maxLines: 10,
                                      )
                                    : ResponsiveText(
                                        "${value.name}(${value.pricePrefix}NT\$${value.price.toString()})",
                                        baseFontSize: 34,
                                        maxLines: 10,
                                      ),
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
                                ResponsiveText(
                                  product['name'],
                                  baseFontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 3,
                                ),
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5.0,
                                    horizontal: 8.0), // 調整文本周圍的空間
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: stockStatus == 1
                                        ? Colors.green
                                        : Colors.red, // 根據庫存狀態設定邊框顏色
                                    width: 1.0, // 邊框寬度
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(5.0), // 邊框圓角
                                ),
                                child: Text(
                                  stockStatus == 1 ? '有現貨' : '缺貨中',
                                  style: TextStyle(
                                      color: stockStatus == 1
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
                                  htmlContent: snapshot.data['details']
                                      ['description'],
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
              if (isLogin == true && stockStatus == 1) {
                await addToCart(
                    widget.productId, _selectedQuantity, selectedOptionValues);
                selectedIndex = 3;
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => MyApp()));
              } else {
                if (stockStatus == 1)
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
                            child: const Text('取消'),
                            onPressed: () {
                              Navigator.of(context).pop(); // 关闭对话框
                            },
                          ),
                          TextButton(
                            child: const Text('登入'),
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
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  stockStatus == 1 ? Colors.white : Colors.grey, // 按钮背景颜色为蓝色
              foregroundColor: const Color(0xFF4F4E4C), // 文本颜色为白色
              minimumSize: const Size(double.infinity, 36), // 按钮最小尺寸，宽度占满
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(
                    color: stockStatus == 1
                        ? Colors.black
                        : Colors.grey), // 设置按钮圆角
              ),
            ),
            child: stockStatus == 1
                ? const InlineTextWidget('加入購物車',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4F4E4C),
                    ))
                : const InlineTextWidget('商品已售完',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    )),
          ),
        ),
      ),
    );
  }

  //TODO： 分享對話框
  void displayShareDialog(BuildContext context, String productName) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)), // Rounded corners
          child: Container(
            padding: const EdgeInsets.all(20.0),
            height: 120, // Set the height of the dialog
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .spaceEvenly, // Center the icons horizontally
                  children: <Widget>[
                    IconButton(
                        icon: const Icon(FontAwesomeIcons.shareNodes,
                            color: Colors.blue, size: 40),
                        onPressed: () {
                          String url;
                          if (isLogin == true) {
                            url =
                                "分享連接：https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${widget.productId}&tracking=nXnYCxN98euUt7G1yrN69jd6jNMH4gcoO80nH4505z50IkvZbeHrOpb7vrUi5kou";
                          } else {
                            url =
                                "分享連接：https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${widget.productId}";
                          }

                          Share.share(url);
                        }),
                    IconButton(
                        icon: const Icon(FontAwesomeIcons.line,
                            color: Colors.green, size: 40),
                        onPressed: () {
                          launchLINE(widget.productId, productName);
                        }),
                    // if (fetchData2['status'] == '1')
                    IconButton(
                        icon: const Icon(FontAwesomeIcons.facebookMessenger,
                            color: Colors.blue, size: 40),
                        onPressed: () {
                          launchFacebook(widget.productId, productName);
                        }),
                    IconButton(
                        icon: const Icon(FontAwesomeIcons.twitter,
                            color: Colors.blue, size: 40),
                        onPressed: () {
                          launchTwitter(widget.productId, productName);
                        }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> launchLINE(String productId, String productName) async {
    String url;
    if (isLogin == true) {
      url =
          "https://www.addtoany.com/add_to/line?linkurl=https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${productId}&tracking=nXnYCxN98euUt7G1yrN69jd6jNMH4gcoO80nH4505z50IkvZbeHrOpb7vrUi5kou&linkname=${productName}&linknote=";
    } else {
      url =
          "https://www.addtoany.com/add_to/line?linkurl=https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${productId}&linkname=${productName}&linknote=";
    }
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> launchFacebook(String productId, String productName) async {
    String url;
    if (isLogin == true) {
      url =
          "https://www.addtoany.com/add_to/facebook?linkurl=https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${productId}&tracking=nXnYCxN98euUt7G1yrN69jd6jNMH4gcoO80nH4505z50IkvZbeHrOpb7vrUi5kou&linkname=${productName}&linknote=";
    } else {
      url =
          "https://www.addtoany.com/add_to/facebook?linkurl=https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${productId}&linkname=${productName}&linknote=";
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> launchTwitter(String productId, String productName) async {
    String url;
    if (isLogin == true) {
      url =
          "https://www.addtoany.com/add_to/twitter?linkurl=https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${productId}&tracking=nXnYCxN98euUt7G1yrN69jd6jNMH4gcoO80nH4505z50IkvZbeHrOpb7vrUi5kou&linkname=${productName}&linknote=";
    } else {
      url =
          "https://www.addtoany.com/add_to/twitter?linkurl=https://ocapi.remember1688.com/index.php?route=product/product&amp;product_id=${productId}&linkname=${productName}&linknote=";
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Widget buildIndicator(int currentIndex, int itemCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        itemCount,
        (index) => Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
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
    // print(node);
    if (node is dom.Element) {
      switch (node.localName) {
        case 'img':
          var imgSrc = node.attributes['src'];
          if (imgSrc != null) {
            widgetsList.add(Image.network(
              imgSrc,
              width: double.infinity, // Set width to screen width
            ));
          }
          break;
        case 'h1':
          widgetsList.add(Text(node.text,
              style: TextStyle(
                  fontSize: baseFontSize, fontWeight: FontWeight.bold)));
          break;
        case 'p':
          widgetsList
              .add(Text(node.text, style: TextStyle(fontSize: baseFontSize)));
          break;

        // ... Handle other HTML tags
      }
    } else if (node is dom.Text) {
      widgetsList
          .add(Text(node.text, style: TextStyle(fontSize: baseFontSize)));
    }
  });

  // print(widgetsList);

  return widgetsList;
}

List<Widget> convertHtml(String htmlContent, {double baseFontSize = 14}) {
  var document = html_parser.parse(htmlContent);
  List<Widget> widgets = [];

  // 處理各種 HTML 標籤並轉換為 Widget
  for (var node in document.body!.nodes) {
    if (node is dom.Element) {
      switch (node.localName) {
        case 'img':
          var src = node.attributes['src'];
          if (src != null && src.isNotEmpty) {
            // print{'Trying to load image from: $src'); // 確保這裡的 URL 被打印出來
            widgets.add(Image.network(
              src,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object exception,
                  StackTrace? stackTrace) {
                // print{'Failed to load image: $src'); // 如果圖片加載失敗，這會被打印
                return const Text('Failed to load image');
              },
            ));
          } else {
            print('No src found for image'); // 如果 src 屬性不存在或為空
          }
          break;
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
        case 'h5':
        case 'h6':
          widgets.add(Text(
            node.text,
            style:
                TextStyle(fontSize: baseFontSize, fontWeight: FontWeight.bold),
          ));
          break;
        case 'p':
          widgets.add(Text(
            node.text.trim(),
            style: TextStyle(fontSize: baseFontSize),
          ));
          break;
        case 'li':
          widgets.add(Row(
            children: <Widget>[
              Text('• ', style: TextStyle(fontSize: baseFontSize)),
              Expanded(
                  child:
                      Text(node.text, style: TextStyle(fontSize: baseFontSize)))
            ],
          ));
          break;

        case 'ol':
        case 'ul':
          widgets.add(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: node.children
                .map((child) => convertHtml(child.outerHtml))
                .expand((i) => i)
                .toList(),
          ));
          break;
        case 'b':
        case 'strong':
          widgets.add(Text(
            node.text,
            style:
                TextStyle(fontSize: baseFontSize, fontWeight: FontWeight.bold),
          ));
          break;
        case 'br':
          widgets.add(SizedBox(height: baseFontSize / 2));
          break;
        default:
          if (node.text.trim().isNotEmpty) {
            widgets.add(Text(
              node.text,
              style: TextStyle(fontSize: baseFontSize),
            ));
          }
          break;
      }
    }
  }

  return widgets;
}

class MyHtmlWidget extends StatelessWidget {
  final String htmlContent;
  final double baseFontSize;

  MyHtmlWidget({Key? key, required this.htmlContent, this.baseFontSize = 14})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // print{htmlContent);
    List<Widget> widgets = convertHtml(htmlContent, baseFontSize: baseFontSize);

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
  void reassemble() {
    super.reassemble();
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
                icon: const Icon(Icons.remove, color: Colors.black),
                onPressed: decrementQuantity,
                constraints: const BoxConstraints(
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
                icon: const Icon(Icons.add, color: Colors.black),
                onPressed: incrementQuantity,
                constraints: const BoxConstraints(
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

Future<void> addToCart(
    String productId, int quantity, selectedOptionValues) async {
  final formData = FormData.fromMap({
    'product_id': productId,
    'quantity': quantity,
    'option': selectedOptionValues,
  });

  // print{productId);
  // print{quantity);
  // print{selectedOptionValues);

  final addCartUrl =
      '${appUri}/gws_appcustomer_cart/add&customer_id=${customerId}&api_key=${apiKey}';
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
