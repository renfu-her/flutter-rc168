import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/shop/shop_cart_page.dart';

class ShopPage extends StatefulWidget {
  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  List<Product> products = [];
  bool isLoading = true;
  double totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    final customerCartUrl =
        '${appUri}/gws_customer_cart&customer_id=${customerId}&api_key=${apiKey}';
    final productDetailBaseUrl = '${appUri}/gws_product&product_id=';
    // print('${customerId}');

    setState(() {
      products.clear();
      totalAmount = 0.0;
      isLoading = true;
    });
    try {
      // Fetch the cart items
      var cartResponse = await dio.get(customerCartUrl);
      var cartData = cartResponse.data;

      if (cartData['message'][0]['msg_status'] == true) {
        // Fetch details for each product in the cart
        for (var cartItem in cartData['customer_cart']) {
          var productResponse = await dio.get(
              '$productDetailBaseUrl${cartItem['product_id']}&api_key=${apiKey}');
          var productData = productResponse.data;

          if (productData['message'][0]['msg_status'] == true) {
            // 創建一個組合了所有必要數據的新 Map
            var combinedData =
                Map<String, dynamic>.from(productData['product'][0])
                  ..addAll({
                    'quantity': cartItem['quantity'],
                    'cart_id': cartItem['cart_id'],
                  });

            var product = Product.fromJson(combinedData);

            setState(() {
              products.add(product);
              totalAmount += product.price * product.quantity;
            });
          }
        }
      }
    } on DioException catch (e) {
      // Handle errors
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateQuantity(String cartId, int quantity) async {
    if (quantity == 0) {
      // 当数量为0时，调用删除API
      try {
        var response = await dio.get(
          '${appUri}/gws_customer_cart/remove&customer_id=${customerId}&cart_id=$cartId&api_key=${apiKey}',
        );

        if (response.data['message'][0]['msg_status'] == true) {
          fetchCartItems(); // 重新获取购物车数据
        }
      } on DioException catch (e) {
        // 处理错误
        print(e);
      }
    } else {
      // 当数量不为0时，更新购物车中的项目数量
      final formData = FormData.fromMap({
        'quantity': quantity,
      });

      try {
        var response = await dio.post(
          '${appUri}/gws_customer_cart/edit&customer_id=${customerId}&cart_id=$cartId&api_key=${apiKey}',
          data: formData,
        );

        if (response.data['message'][0]['msg_status'] == true) {
          fetchCartItems(); // 重新获取购物车数据
        }
      } on DioException catch (e) {
        // 处理错误
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('購物車'),
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty // 如果產品列表為空
              ? Center(
                  // 顯示購物車空的提示畫面
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.shopping_cart,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      Text(
                        '您的購物車是空的!',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey[400],
                        ),
                      ),
                      SizedBox(height: 20),
                      // ElevatedButton(
                      //   onPressed: () {
                      //     // 這裡添加按鈕的行為，例如返回商店頁面
                      //   },
                      //   child: Text('開始選購'),
                      //   style: ElevatedButton.styleFrom(
                      //     foregroundColor: Theme.of(context).primaryColor,
                      //   ),
                      // )
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '商品總計',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'NT\$${totalAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.grey, // 您可以選擇線的顏色
                      thickness: 1, // 線的厚度
                      height: 20, // 與其他元素的間距
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length,
                        padding: EdgeInsets.only(bottom: 100.0),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            leading: Image.network(
                              '${imgUrl}' + product.thumbUrl,
                              width: 80,
                            ),
                            title: Text(product.name +
                                "\nNT\$" +
                                product.price.toString()),
                            subtitle: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove),
                                  onPressed: () async {
                                    if (product.quantity == 1) {
                                      // 當數量為1時，顯示確認對話框
                                      final confirmDelete =
                                          await showDialog<bool>(
                                        context: context, // 這裡需要提供BuildContext
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('確認'),
                                            content: Text('是否要刪除該項目？'),
                                            actions: <Widget>[
                                              TextButton(
                                                child: Text('取消'),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false), // 不刪除
                                              ),
                                              TextButton(
                                                child: Text('確定刪除'),
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(true), // 確認刪除
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmDelete ?? false) {
                                        await updateQuantity(product.cartId, 0);
                                      }
                                    } else {
                                      // 若數量不為1，正常增加數量
                                      setState(() {
                                        product.decrementQuantity();
                                      });
                                      await updateQuantity(
                                          product.cartId, product.quantity);
                                    }
                                  },
                                ),
                                Text('数量: ${product.quantity}'),
                                IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () async {
                                      // 若數量不為1，正常增加數量
                                      setState(() {
                                        product.incrementQuantity();
                                      });
                                      await updateQuantity(
                                          product.cartId, product.quantity);
                                    }),
                              ],
                            ),
                            trailing: Text(
                              '小計 NT\$' +
                                  (product.price * product.quantity).toString(),
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      bottomSheet: Container(
        color: Colors.white,
        width: double.infinity, // 容器宽度占满整个屏幕宽度
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: isLoading
              ? ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ShopCartPage()));
                  },
                  child: const Text(
                    '結 帳',
                    style: TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey, // 按钮背景颜色为灰色
                    foregroundColor: Colors.white, // 文本颜色为白色
                    minimumSize: Size(double.infinity, 36), // 按钮最小尺寸，宽度占满
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6), // 圆角矩形按钮
                    ),
                  ),
                )
              : products.isEmpty
                  ? ElevatedButton(
                      onPressed: () {
                        // 当购物车为空时，跳转到逛逛賣場
                        Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => MyApp()));
                      },
                      child: const Text(
                        '逛逛賣場',
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
                    )
                  : ElevatedButton(
                      onPressed: () {
                        // 这里添加结账逻辑
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ShopCartPage()));
                      },
                      child: const Text(
                        '結 帳',
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
}

class Product {
  final String productId;
  final String name;
  final String thumbUrl;
  final int price;
  int quantity;
  final String cartId;

  void incrementQuantity() {
    quantity++;
  }

  void decrementQuantity() {
    if (quantity > 0) {
      quantity--;
    }
  }

  Product({
    required this.productId,
    required this.name,
    required this.thumbUrl,
    required this.price,
    required this.quantity,
    required this.cartId,
  });

  // 工廠構造函數
  factory Product.fromJson(Map<String, dynamic> combinedJson) {
    return Product(
      productId: combinedJson['product_id'],
      name: combinedJson['name'],
      thumbUrl: combinedJson['thumb'],
      price:
          int.parse(combinedJson['price'].replaceAll(RegExp(r'[^0-9\.]'), '')),
      quantity: int.parse(combinedJson['quantity']),
      cartId: combinedJson['cart_id'],
    );
  }
}
