import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/shop/shop_cart_page.dart';
import 'package:rc168/pages/shop/shop_page.dart';
import 'package:text_responsive/text_responsive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rc168/pages/product_detail.dart';
import 'package:rc168/responsive_text.dart';
import 'package:rc168/pages/shop/shop_reporchase.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({Key? key}) : super(key: key);

  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Future<List<Order>>? futureOrders;

  @override
  void initState() {
    super.initState();
    futureOrders = fetchOrders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('訂單資訊'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4F4E4C),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Order>>(
        future: futureOrders,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                Order order = snapshot.data![index];
                return ListTile(
                  title: InlineTextWidget(
                    '訂單號碼 #${order.orderId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            const TextSpan(
                                text: '    ',
                                style: TextStyle(
                                    color: Colors.black)), // 使用空格来创建前缀空间
                            const TextSpan(
                                text: '商品数量: ',
                                style: TextStyle(
                                  color: Colors.black,
                                )),
                            TextSpan(
                                text: order.products.toString(),
                                style: const TextStyle(color: Colors.black)),
                            const TextSpan(
                                text: '\n    ',
                                style: TextStyle(
                                    color: Colors.black)), // 使用空格来创建前缀空间
                            const TextSpan(
                                text: '商品金額: ',
                                style: TextStyle(
                                  color: Colors.black,
                                )),
                            TextSpan(
                                text: order.total.toString(),
                                style: const TextStyle(color: Colors.black)),
                            const TextSpan(
                                text: '\n    ',
                                style: TextStyle(
                                    color: Colors.black)), // 使用空格来创建前缀空间
                            const TextSpan(
                                text: '訂單日期: ',
                                style: TextStyle(
                                  color: Colors.black,
                                )),
                            TextSpan(
                                text: order.dateAdded,
                                style: const TextStyle(color: Colors.black)),
                            const TextSpan(
                                text: '\n    ',
                                style: TextStyle(
                                    color: Colors.black)), // 使用空格来创建前缀空间
                            const TextSpan(
                                text: '訂單狀態: ',
                                style: TextStyle(
                                  color: Colors.black,
                                )),
                            TextSpan(
                                text: order.status,
                                style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                      )
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize:
                        MainAxisSize.min, // 重要：這確保 Row 只佔用其子 widgets 所需的最小空間
                    children: <Widget>[
                      IconButton(
                        icon: const Icon(FontAwesomeIcons
                            .circleInfo), // 詳情圖標，請確保已經加載了 FontAwesome
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ShopRepurchasePage(
                                    orderId: order.orderId,
                                  )));
                          //   getOrder(order.orderId);

                          //   _showDialog('重新下單成功', '已經重新下單。');

                          //   selectedIndex = 3;
                          //   Navigator.of(context).push(
                          //       MaterialPageRoute(builder: (context) => MyApp()));
                        },
                      ),
                      // IconButton(
                      //   icon: const Icon(FontAwesomeIcons
                      //       .cartShopping), // 詳情圖標，請確保已經加載了 FontAwesome
                      //   onPressed: () {
                      //     getOrder(order.orderId);

                      //     _showDialog('重新下單成功', '已經重新下單。');

                      //     Navigator.of(context).push(MaterialPageRoute(
                      //         builder: (context) => ShopPage()));
                      //   },
                      // ),
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

Future<List<Order>> fetchOrders() async {
  final response = await dio.get(
      '$appUri/gws_appcustomer_order&customer_id=$customerId&api_key=$apiKey');

  if (response.statusCode == 200) {
    List<Order> orders = (response.data['orders'] as List)
        .map((order) => Order.fromJson(order))
        .toList();

    // print(orders);
    return orders;
  } else {
    throw Exception('Failed to load orders');
  }
}

Future<void> getOrder(String orderId) async {
  final response = await dio.get(
      '$appUri/gws_appcustomer_order/info&&order_id=$orderId&customer_id=$customerId&api_key=$apiKey');

  if (response.statusCode == 200) {
    // print(response.data['products']);

    List<dynamic> products = response.data['products'];

    for (var product in products) {
      String reorderUrl = product['reorder'].replaceAll('&amp;', '&');
      var reorderResponse = await dio.get(reorderUrl + '&api_key=$apiKey');
      if (reorderResponse.statusCode == 200) {
        print('Reordered product successfully: ${product['name']}');
      } else {
        print('Failed to reorder product: ${product['name']}');
      }
    }
  } else {
    throw Exception('Failed to load orders');
  }
}

class Order {
  final String orderId;
  final String name;
  final String status;
  final String dateAdded;
  final int products;
  final String total;

  Order({
    required this.orderId,
    required this.name,
    required this.status,
    required this.dateAdded,
    required this.products,
    required this.total,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      orderId: json['order_id'],
      name: json['name'],
      status: json['status'],
      dateAdded: json['date_added'],
      products: json['products'],
      total: json['total'],
    );
  }
}
