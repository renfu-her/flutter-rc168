import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:rc168/main.dart';
import 'package:rc168/pages/shop/shop_payment_page.dart';
import 'package:rc168/pages/member/address/address_cart_page.dart';
import 'package:text_responsive/text_responsive.dart';
import 'package:rc168/responsive_text.dart';
import 'package:rc168/pages/shop/shop_payment_bankTransfer_page.dart';

import 'models/product.dart';
import 'models/shipping_method.dart';
import 'models/coupon.dart';
import 'widgets/shipping_method_list.dart';
import 'widgets/product_list_item.dart';
import 'widgets/address_info.dart';
import 'services/cart_service.dart';
import 'services/shipping_service.dart';
import 'services/payment_service.dart';
import 'services/coupon_service.dart';

class ShopCartPage extends StatefulWidget {
  final String? addressId;
  const ShopCartPage({Key? key, this.addressId}) : super(key: key);

  @override
  _ShopCartPageState createState() => _ShopCartPageState();
}

class _ShopCartPageState extends State<ShopCartPage> {
  final CartService _cartService = CartService(Dio());
  final ShippingService _shippingService = ShippingService(Dio());
  final PaymentService _paymentService = PaymentService(Dio());
  final CouponService _couponService = CouponService(Dio());

  List<Product> products = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  int? _selectedShippingMethodCode;
  String? _selectedPaymentMethod;
  double _selectedShippingCost = 0.0;
  double _tempTotalAmount = 0.0;
  List<DropdownMenuItem<String>> _dropdownItems = [];
  List<Coupon> availableCoupons = [];
  Coupon? selectedCoupon;
  double discountedAmount = 0.0;
  Map<String, dynamic>? customerAddress;
  Map<String, dynamic>? customerData;
  String customerId = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      fetchCartItems(),
      _fetchPaymentMethods(),
      getCustomerDataAndFetchAddress(widget.addressId),
      fetchAvailableCoupons(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchCartItems() async {
    final fetchedProducts = await _cartService.fetchCartItems(customerId);
    setState(() {
      products = fetchedProducts;
      totalAmount = products.fold(
          0,
          (sum, product) =>
              sum +
              (product.special != false ? product.special : product.price) *
                  product.quantity);
      _tempTotalAmount = totalAmount;
    });
  }

  Future<void> _fetchPaymentMethods() async {
    _dropdownItems = await _paymentService.fetchPaymentMethods(customerId);
  }

  Future<void> getCustomerDataAndFetchAddress(String? defaultAddressId) async {
    customerData = await _cartService.fetchCustomerData(customerId);
    await fetchCustomerAddress(
        defaultAddressId: defaultAddressId ??
            customerData!['customer'][0]['default_address_id']);
  }

  Future<void> fetchCustomerAddress({required String defaultAddressId}) async {
    customerAddress =
        await _cartService.fetchCustomerAddress(customerId, defaultAddressId);
  }

  Future<void> fetchAvailableCoupons() async {
    availableCoupons = await _couponService.fetchAvailableCoupons();
  }

  void showCouponDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('選擇折扣券'),
              content: SingleChildScrollView(
                child: Column(
                  children: availableCoupons.map((coupon) {
                    bool isApplicable =
                        totalAmount >= double.parse(coupon.total);
                    return ListTile(
                      title: Text(coupon.name),
                      subtitle: Text(
                          '${coupon.type == 'F' ? 'NT\$' : ''}${coupon.discount}${coupon.type == 'P' ? '%' : ''}'),
                      leading: Radio<Coupon>(
                        value: coupon,
                        groupValue: selectedCoupon,
                        onChanged: isApplicable
                            ? (Coupon? value) {
                                setState(() {
                                  selectedCoupon = value;
                                });
                              }
                            : null,
                      ),
                      enabled: isApplicable,
                    );
                  }).toList(),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('確定'),
                  onPressed: () {
                    applySelectedCoupon();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void applySelectedCoupon() {
    setState(() {
      if (selectedCoupon != null) {
        if (selectedCoupon!.type == 'F') {
          discountedAmount =
              totalAmount - double.parse(selectedCoupon!.discount);
        } else if (selectedCoupon!.type == 'P') {
          double discountPercentage =
              double.parse(selectedCoupon!.discount) / 100;
          discountedAmount = totalAmount * (1 - discountPercentage);
        }
      }
    });
  }

  Future<void> submitOrder() async {
    if (_selectedPaymentMethod == null || _selectedShippingMethodCode == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: ResponsiveText('溫馨提醒!', baseFontSize: 38),
            content: ResponsiveText(
              '您尚未選定付款方式或物流方式。',
              baseFontSize: 36,
              maxLines: 5,
            ),
            actions: <Widget>[
              TextButton(
                child: ResponsiveText('確定', baseFontSize: 36),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    double couponDiscount =
        selectedCoupon != null ? totalAmount - discountedAmount : 0;

    final orderData = _cartService.prepareOrderData(
      customerAddress!['address_id'],
      customerData!['customer'],
      products,
      _selectedShippingMethodCode!,
      _selectedPaymentMethod!,
      _selectedShippingCost,
      discountedAmount,
      couponDiscount,
      selectedCoupon,
    );

    final response = await _cartService.submitOrder(customerId, orderData);

    if (response.statusCode == 200) {
      final responseData = response.data['data'];
      final htmlUrl =
          '${demoUrl}/api/product/payment?customerId=${customerId}&orderId=${responseData['order']['order_id']}&api_key=${apiKey}';

      if (_selectedPaymentMethod == 'bank_transfer') {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ShopPaymentBankTransferPage(htmlUrl: htmlUrl)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopPaymentPage(htmlUrl: htmlUrl)),
        );
      }
    } else {
      print('Failed to submit order: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('購物車'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF4F4E4C),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? _buildEmptyCart()
              : _buildCartContent(),
      bottomSheet: _buildBottomSheet(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey[400]),
          InlineTextWidget(
            '您的購物車是空的!',
            style: TextStyle(fontSize: 22, color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        _buildTotalAmount(),
        const Divider(color: Colors.grey, thickness: 0.5, height: 20),
        _buildCouponButton(),
        if (selectedCoupon != null) _buildDiscountedAmount(),
        _buildPaymentMethodDropdown(),
        Expanded(
          child: ListView.builder(
            itemCount: products.length + 2,
            padding: const EdgeInsets.only(bottom: 100.0),
            itemBuilder: (context, index) {
              if (index == 0 && customerAddress != null) {
                return AddressInfo(
                  address: customerAddress!,
                  onEditPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddressCartAddPage()),
                    );
                  },
                );
              } else if (index == products.length + 1) {
                return FutureBuilder<List<ShippingMethod>>(
                  future: _shippingService.fetchShippingMethods(
                      customerId, customerAddress!['address_id']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasData) {
                      return ShippingMethodList(
                        methods: snapshot.data!,
                        selectedMethodCode: _selectedShippingMethodCode,
                        onMethodSelected: (int? value) {
                          setState(() {
                            _selectedShippingMethodCode = value;
                            _selectedShippingCost = snapshot.data!
                                .firstWhere(
                                    (method) => method.sortOrder == value)
                                .cost
                                .toDouble();
                            totalAmount =
                                _tempTotalAmount + _selectedShippingCost;
                          });
                        },
                      );
                    } else {
                      return const Text('No shipping methods available');
                    }
                  },
                );
              } else {
                final product = products[index - 1];
                return ProductListItem(product: product);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalAmount() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText('商品總計', baseFontSize: 34, fontWeight: FontWeight.bold),
          ResponsiveText('NT\$${totalAmount.toStringAsFixed(0)}',
              baseFontSize: 34, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildCouponButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: showCouponDialog,
        child: Text('選擇折扣券'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4F4E4C),
          side: BorderSide(color: Color(0xFF4F4E4C)),
        ),
      ),
    );
  }

  Widget _buildDiscountedAmount() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText('折扣後金額',
              baseFontSize: 34, fontWeight: FontWeight.bold),
          ResponsiveText('NT\$${discountedAmount.toStringAsFixed(0)}',
              baseFontSize: 34, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return Column(
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
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
            isExpanded: true,
            value: _selectedPaymentMethod,
            items: _dropdownItems,
            onChanged: (String? value) {
              setState(() {
                _selectedPaymentMethod = value;
              });
            },
            hint: Text('選擇付款方式'),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSheet() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: isLoading
            ? ElevatedButton(
                onPressed: submitOrder,
                child: const InlineTextWidget('確定下訂單',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Color(0xFF4F4E4C),
                  minimumSize: Size(double.infinity, 36),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              )
            : products.isEmpty
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => MyApp()));
                    },
                    child: InlineTextWidget('逛逛賣場',
                        style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF4F4E4C),
                      minimumSize: Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                  )
                : ElevatedButton(
                    onPressed: submitOrder,
                    child: InlineTextWidget('確定下訂單',
                        style: const TextStyle(
                            fontSize: 18, color: Color(0xFF4F4E4C))),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xFF4F4E4C),
                      minimumSize: Size(double.infinity, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
      ),
    );
  }
}
