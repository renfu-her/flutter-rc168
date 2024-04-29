import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/shop/shop_payment_page.dart';
import 'package:rc168/pages/member/address/address_cart_page.dart';
import 'package:text_responsive/text_responsive.dart';
import 'package:rc168/responsive_text.dart';

class ShopCartPage extends StatefulWidget {
  // final String? addressId;
  // const ShopCartPage({super.key, required this.addressId});

  @override
  _ShopCartPageState createState() => _ShopCartPageState();
}

class _ShopCartPageState extends State<ShopCartPage> {
  List<Product> products = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  int? _selectedShippingMethodCode;
  String? _selectedPaymentMethod;
  double _selectedShippingCost = 0.0;
  double _tempTotalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    getCustomerDataAndFetchAddress();
    // if (widget.addressId != null) {
    //   String? address = widget.addressId;
    //   print('address: ${widget.addressId}');
    //   fetchCustomerAddress(defaultAddressId: address!);
    // } else {
    //   getCustomerDataAndFetchAddress();
    // }
    // fetchShippingMethods();
  }

  Future<void> getCustomerDataAndFetchAddress() async {
    try {
      // 從 gws_customer 獲取用戶資料
      var customerResponse = await dio.get('${appUri}/gws_customer',
          queryParameters: {'customer_id': customerId, 'api_key': apiKey});
      var customer = customerResponse.data;

      // 提取 default_address_id
      String defaultAddressId =
          customer['customer'][0]['default_address_id'] ?? '';
      customerData = customer;
      // 使用提取的 default_address_id 調用 fetchCustomerAddress
      await fetchCustomerAddress(defaultAddressId: defaultAddressId);
    } catch (e) {
      print(e);
      // 處理異常或顯示錯誤信息
    }
  }

  Future<void> fetchCartItems() async {
    final customerCartUrl =
        '${appUri}/gws_customer_cart&customer_id=${customerId}&api_key=${apiKey}';
    final productDetailBaseUrl = '${appUri}/gws_product&product_id=';

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
              _tempTotalAmount += product.price * product.quantity;
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

  Future<void> fetchCustomerAddress({String defaultAddressId = ''}) async {
    try {
      // 如果有提供 defaultAddressId，則直接使用
      String addressId = defaultAddressId;

      if (addressId.isEmpty) {
        // 如果沒有提供 defaultAddressId，則從 gws_customer 獲取
        var customerResponse = await dio.get('${appUri}/gws_customer',
            queryParameters: {'customer_id': customerId, 'api_key': apiKey});
        var customerData = customerResponse.data;
        addressId = customerData['default_address_id'] ?? '';
      }

      Response addressResponse;
      if (addressId.isNotEmpty) {
        // print('fetchCustomerAddress: ${addressId}');
        // Fetch specific address
        addressResponse = await dio.get('$appUri/gws_customer_address',
            queryParameters: {
              'customer_id': customerId,
              'address_id': addressId,
              'api_key': apiKey
            });
      } else {
        // Fetch first address from address list
        addressResponse = await dio.get('${appUri}/gws_customer_address',
            queryParameters: {'customer_id': customerId, 'api_key': apiKey});
      }

      var addressData = addressResponse.data;

      setState(() {
        // 根據 status 決定如何處理地址
        if (addressData['message'][0]['msg_status']) {
          customerAddress = addressData['customer_address'][0];
        } else {
          // 如果 status 為 false，選擇最新地址或其他邏輯
        }

        print('customerAddress: ${customerAddress}');
      });
    } catch (e) {
      print(e);
      // Handle exceptions or show error messages
    }
  }

  Future<Map<String, dynamic>?> fetchCountryAndZoneDetails(
      String countryId) async {
    try {
      // 獲取國家信息
      var countryResponse = await dio.get('$appUri/gws_country',
          queryParameters: {'country_id': countryId, 'api_key': apiKey});
      var countryData = countryResponse.data;

      // 檢查國家信息是否成功獲取
      if (countryData['message'][0]['msg_status'] == true) {
        // 獲取區域列表
        var zoneResponse = await dio.get('$appUri/gws_zone',
            queryParameters: {'country_id': countryId, 'api_key': apiKey});
        var zoneData = zoneResponse.data;

        // 檢查區域信息是否成功獲取
        if (zoneData['message'][0]['msg_status'] == true) {
          // 假定您需要第一個區域的信息
          var firstZone =
              zoneData['zones'].isNotEmpty ? zoneData['zones'][0] : null;

          if (firstZone != null) {
            // 返回國家和區域的詳細信息
            return {'country': countryData['country'][0], 'zone': firstZone};
          }
        }
      }
    } on DioException catch (e) {
      print(e);
    }
    return null;
  }

  Widget buildShippingMethodList(List<ShippingMethod> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: ResponsiveText(
              '物流方式',
              baseFontSize: 34, // 字體大小
              fontWeight: FontWeight.bold, // 字體加粗
            )),
        ...methods.map((method) {
          return ListTile(
            leading: Radio<int>(
              value: method.sortOrder!,
              groupValue: _selectedShippingMethodCode,
              onChanged: (int? value) {
                setState(() {
                  _selectedShippingMethodCode = value!;
                  _selectedShippingCost = method.cost?.toDouble() ?? 0.0;
                  totalAmount = _tempTotalAmount;
                  totalAmount = totalAmount + _selectedShippingCost;
                });
              },
            ),
            title: ResponsiveText(
              method.title,
              baseFontSize: 32, // 字體大小
            ),
            trailing: ResponsiveText(
              'NT\$${method.cost}',
              baseFontSize: 34, // 字體大小
              fontWeight: FontWeight.bold, // 字體加粗
            ),
            onTap: () {
              setState(() {
                _selectedShippingMethodCode = method.sortOrder;
                _selectedShippingCost = method.cost?.toDouble() ?? 0.0;
                totalAmount = _tempTotalAmount;
                totalAmount = totalAmount + _selectedShippingCost;
              });
            },
          );
        }).toList(),
      ],
    );
  }

  Future<List<ShippingMethod>> fetchShippingMethods() async {
    final response = await dio.get(
      '${appUri}/gws_taxshippingestimate',
      queryParameters: {
        'country_id': 206,
        'zone_id': 3136,
        'api_key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(response.data['shipping_method']);
      List<ShippingMethod> shippingMethods = data.entries.map((e) {
        // 解析每個物流方式並返回 ShippingMethod 對象
        return ShippingMethod.fromJson(e.value);
      }).where((method) {
        // 確保 sortOrder 是正數並且沒有錯誤
        return method.sortOrder! > 0 && !method.error;
      }).toList();
      return shippingMethods;
    } else {
      throw Exception('Failed to load shipping methods');
    }
  }

  Future<void> submitOrder() async {
    if (_selectedPaymentMethod == null || _selectedShippingMethodCode == null) {
      // 使用Flutter的showDialog函数来显示警告对话框
      showDialog(
        context: context, // 确保你有一个BuildContext实例名为context
        builder: (BuildContext context) {
          return AlertDialog(
            title: ResponsiveText('溫馨提醒!', baseFontSize: 36),
            content: ResponsiveText('您尚未選定付款方式或物流方式。', baseFontSize: 30),
            actions: <Widget>[
              TextButton(
                child: ResponsiveText('確定', baseFontSize: 36),
                onPressed: () {
                  Navigator.of(context).pop(); // 关闭对话框
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // 构建请求体数据
    final orderData = {
      'address_id': customerAddress!['address_id'],
      'customer': customerData!['customer'],
      'products': products.map((product) {
        return {
          'product_id': product.productId,
          'quantity': product.quantity,
          'price': product.price,
          'total': product.price * product.quantity,
          'name': product.name
        };
      }).toList(),
      'shipping_sort_order': _selectedShippingMethodCode,
      'payment_method': _selectedPaymentMethod,
      'shipping_cost': _selectedShippingCost,
      'amount': totalAmount,
    };

    final response = await dio.post(
      '${demoUrl}/api/product/submit',
      data: orderData,
    );

    if (response.statusCode == 200) {
      final responseData = response.data['data'];
      final htmlUrl =
          '${demoUrl}/api/product/payment?customerId=${customerId}&orderId=' +
              responseData['order']['order_id'];

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => ShopPaymentPage(htmlUrl: htmlUrl)),
      );
    } else {
      print('Failed to submit order: ${response.statusCode}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('購物車'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
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
                      InlineTextWidget(
                        '您的購物車是空的!',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 20),
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
                          ResponsiveText(
                            '商品總計',
                            baseFontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                          ResponsiveText(
                            'NT\$${totalAmount.toStringAsFixed(0)}',
                            baseFontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      color: Colors.grey, // 您可以選擇線的顏色
                      thickness: 0.5, // 線的厚度
                      height: 20, // 與其他元素的間距
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(16.0),
                          child: ResponsiveText('付款方式',
                              baseFontSize: 34, fontWeight: FontWeight.bold),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              isDense: true, // Reduces the dropdown's height
                            ),
                            isExpanded: true,
                            value: _selectedPaymentMethod,
                            items: [
                              // DropdownMenuItem(
                              //   value: 'bank_transfer',
                              //   child: ResponsiveText('銀行轉帳'),
                              // ),
                              DropdownMenuItem(
                                value: 'linepay_sainent',
                                child: Text('LINE Pay'),
                              ),
                              DropdownMenuItem(
                                value: 'ecpaypayment',
                                child: Text('綠界金流'),
                              ),
                            ],
                            onChanged: (String? value) {
                              setState(() {
                                _selectedPaymentMethod = value;
                              });
                            },
                            hint: Text('選擇付款方式'),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: products.length + 2, // 添加1是为了显示地址信息
                        padding: const EdgeInsets.only(bottom: 100.0),
                        itemBuilder: (context, index) {
                          if (index == 0 && customerAddress != null) {
                            print(customerAddress);
                            // 在列表的最上方显示地址信息
                            return FutureBuilder<Map<String, dynamic>?>(
                              future: fetchCountryAndZoneDetails(
                                  customerAddress!['country_id']),
                              builder: (BuildContext context,
                                  AsyncSnapshot<Map<String, dynamic>?>
                                      snapshot) {
                                if (snapshot.hasData) {
                                  final countryDetails =
                                      snapshot.data!['country'];
                                  final zoneDetails = snapshot.data!['zone'];
                                  return ListTile(
                                    title: ResponsiveText('收貨地址',
                                        baseFontSize: 34,
                                        fontWeight: FontWeight.bold),
                                    subtitle: ResponsiveText(
                                      '${customerAddress!['firstname']} ${customerAddress!['lastname']} \n' +
                                          '${customerAddress!['address_1']} ${customerAddress!['address_2']} \n' +
                                          '${zoneDetails['name']}, ${countryDetails['name']} \n' +
                                          '${customerAddress!['postcode']}',
                                      baseFontSize: 30,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        // 編輯地址的邏輯
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  AddressCartAddPage()),
                                        ).then((selectedAddress) {
                                          print('address: ' + selectedAddress);
                                          if (selectedAddress != null) {
                                            // 更新地址信息
                                            fetchCustomerAddress(
                                                defaultAddressId:
                                                    selectedAddress.id);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                } else {
                                  return const Text('No data');
                                }
                              },
                            );
                          } else if (index == products.length + 1) {
                            // 显示物流信息
                            return FutureBuilder<List<ShippingMethod>>(
                              future: fetchShippingMethods(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  // 使用上面的 buildShippingMethodList 方法构建界面
                                  return buildShippingMethodList(
                                      snapshot.data!);
                                } else {
                                  return const Text(
                                      'No shipping methods available');
                                }
                              },
                            );
                          } else {
                            // 显示商品列表
                            final product = products[index - 1]; // 调整索引以获取正确的商品
                            return ListTile(
                              leading: Image.network(
                                '${imgUrl}' + product.thumbUrl,
                                width: 80,
                              ),
                              title: ResponsiveText(
                                product.name +
                                    "\nNT\$" +
                                    product.price.toString(),
                                baseFontSize: 28,
                              ),
                              subtitle: Row(
                                children: [
                                  ResponsiveText('數量: ${product.quantity}',
                                      baseFontSize: 28),
                                ],
                              ),
                              trailing: ResponsiveText(
                                  'NT\$' +
                                      (product.price * product.quantity)
                                          .toString(),
                                  baseFontSize: 28,
                                  fontWeight: FontWeight.bold),
                            );
                          }
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
                    submitOrder();
                  },
                  child: const InlineTextWidget(
                    '確定下訂單',
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
                      child: InlineTextWidget('逛逛賣場',
                          style: TextStyle(fontSize: 16)),
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
                        submitOrder();
                      },
                      child: InlineTextWidget('確定下訂單',
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

class ShippingMethod {
  String title;
  String costText;
  String code;
  int? cost;
  bool error;
  int? sortOrder;

  ShippingMethod({
    required this.title,
    required this.costText,
    required this.code,
    required this.cost,
    required this.error,
    required this.sortOrder,
  });

  factory ShippingMethod.fromJson(Map<String, dynamic> json) {
    var sortOrderString = json['sort_order']?.toString();
    int? sortOrder = int.tryParse(sortOrderString ?? '0');
    var costString = json['quote'].values.first['cost']?.toString();
    int? cost = int.tryParse(costString ?? '0');

    return ShippingMethod(
      title: json['title'],
      costText: json['quote'].values.first['text'],
      code: json['quote'].values.first['code'],
      cost: cost ?? 0,
      error: json['error'],
      sortOrder: sortOrder ?? 0,
    );
  }
}
