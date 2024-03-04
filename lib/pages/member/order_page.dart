import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/responsive_text.dart';

class OrderPage extends StatefulWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('訂單資訊'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                  title: ResponsiveText(
                    '訂單號碼 #${order.orderId}',
                    fontWeight: FontWeight.bold,
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
                                text: '${order.products.toString()}',
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
                                text: '${order.total.toString()}',
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
                                text: '${order.dateAdded}',
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
                                text: '${order.status}',
                                style: const TextStyle(color: Colors.black)),
                          ],
                        ),
                      )
                    ],
                  ),
                  // trailing: ElevatedButton(
                  //   onPressed: () {
                  //     // 实现点击事件
                  //   },
                  //   child: const Text('再買一次'),
                  // ),
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
  var dio = Dio();
  final response = await dio.get(
      '${appUri}/gws_customer_order&customer_id=${customerId}&api_key=${apiKey}');

  if (response.statusCode == 200) {
    List<Order> orders = (response.data['orders'] as List)
        .map((order) => Order.fromJson(order))
        .toList();
    return orders;
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

  Order(
      {required this.orderId,
      required this.name,
      required this.status,
      required this.dateAdded,
      required this.products,
      required this.total});

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
