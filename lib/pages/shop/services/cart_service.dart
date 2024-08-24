import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/coupon.dart';
import 'package:rc168/main.dart';

class CartService {
  final Dio dio;

  CartService(this.dio);

  Future<List<Product>> fetchCartItems(String customerId) async {
    final customerCartUrl =
        '${appUri}/gws_appcustomer_cart&customer_id=${customerId}&api_key=${apiKey}';
    final productDetailBaseUrl = '${appUri}/gws_product&product_id=';

    try {
      var cartResponse = await dio.get(customerCartUrl);
      var cartData = cartResponse.data;

      if (cartData['message'][0]['msg_status'] == true) {
        List<Product> products = [];
        for (var cartItem in cartData['customer_cart']) {
          var productResponse = await dio.get(
              '$productDetailBaseUrl${cartItem['product_id']}&api_key=${apiKey}');
          var productData = productResponse.data;

          if (productData['message'][0]['msg_status'] == true) {
            var combinedData =
                Map<String, dynamic>.from(productData['product'][0])
                  ..addAll({
                    'quantity': cartItem['quantity'],
                    'cart_id': cartItem['cart_id'],
                    'options': cartItem['option'],
                    'totals': cartData['totals']
                  });

            products.add(Product.fromJson(combinedData));
          }
        }
        return products;
      }
    } catch (e) {
      print('Error fetching cart items: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> fetchCustomerData(String customerId) async {
    try {
      var customerResponse = await dio.get('${appUri}/gws_customer',
          queryParameters: {'customer_id': customerId, 'api_key': apiKey});
      return customerResponse.data;
    } catch (e) {
      print('Error fetching customer data: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchCustomerAddress(
      String customerId, String addressId) async {
    try {
      var addressResponse = await dio.get('$appUri/gws_customer_address',
          queryParameters: {
            'customer_id': customerId,
            'address_id': addressId,
            'api_key': apiKey
          });
      return addressResponse.data['customer_address'][0];
    } catch (e) {
      print('Error fetching customer address: $e');
      return {};
    }
  }

  Map<String, dynamic> prepareOrderData(
    String addressId,
    Map<String, dynamic> customerData,
    List<Product> products,
    int shippingMethodCode,
    String paymentMethod,
    double shippingCost,
    double discountedAmount,
    double couponDiscount,
    Coupon? selectedCoupon,
  ) {
    final orderData = {
      'address_id': addressId,
      'customer': customerData,
      'products': products.map((product) {
        return {
          'product_id': product.productId,
          'quantity': product.quantity,
          'price': product.special != false ? product.special : product.price,
          'total': product.special != false
              ? product.special * product.quantity
              : product.price * product.quantity,
          'name': product.name,
          'options': product.options.map((option) {
            return {
              'product_option_id': option.productOptionId,
              'product_option_value_id': option.productOptionValueId,
              'type': option.type,
              'value': option.value,
              'name': option.name,
            };
          }).toList(),
        };
      }).toList(),
      'shipping_sort_order': shippingMethodCode,
      'payment_method': paymentMethod,
      'shipping_cost': shippingCost,
      'totals': products.isNotEmpty ? products[0].totals : [],
      'amount': discountedAmount,
      'coupon_price': selectedCoupon != null ? couponDiscount.toString() : '',
    };

    if (selectedCoupon != null) {
      orderData['coupon'] = {
        'coupon_id': selectedCoupon.couponId,
        'name': selectedCoupon.name,
        'code': selectedCoupon.code,
        'type': selectedCoupon.type,
        'discount': selectedCoupon.discount,
      };
    }

    return orderData;
  }

  Future<Response> submitOrder(
      String customerId, Map<String, dynamic> orderData) async {
    try {
      await dio.post('${demoUrl}/api/product/order/data/${customerId}',
          data: orderData);
      final response =
          await dio.get('${demoUrl}/api/product/submit/${customerId}');
      return response;
    } catch (e) {
      print('Error submitting order: $e');
      throw e;
    }
  }

  Future<void> updateCartItemQuantity(
      String customerId, String cartId, int quantity) async {
    try {
      await dio.post(
        '${appUri}/gws_appcustomer_cart/update',
        queryParameters: {
          'api_key': apiKey,
          'customer_id': customerId,
          'cart_id': cartId,
          'quantity': quantity,
        },
      );
    } catch (e) {
      print('Error updating cart item quantity: $e');
      throw e;
    }
  }

  Future<void> removeCartItem(String customerId, String cartId) async {
    try {
      await dio.post(
        '${appUri}/gws_appcustomer_cart/remove',
        queryParameters: {
          'api_key': apiKey,
          'customer_id': customerId,
          'cart_id': cartId,
        },
      );
    } catch (e) {
      print('Error removing cart item: $e');
      throw e;
    }
  }
}
