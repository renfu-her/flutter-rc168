import 'package:dio/dio.dart';
import '../models/shipping_method.dart';
import 'package:rc168/main.dart';

class ShippingService {
  final Dio dio;

  ShippingService(this.dio);

  Future<List<ShippingMethod>> fetchShippingMethods(
      String customerId, String addressId) async {
    try {
      final response = await dio.get(
        '${appUri}/gws_appshipping_methods/index',
        queryParameters: {
          'api_key': apiKey,
          'customer_id': customerId,
          'address_id': addressId,
        },
      );

      if (response.statusCode == 200) {
        final data = Map<String, dynamic>.from(response.data);
        if (data['message'][0]['msg_status'] == true) {
          List<ShippingMethod> shippingMethods = List<ShippingMethod>.from(
            data['shipping_methods']
                .map((item) => ShippingMethod.fromJson(item)),
          ).where((method) {
            return !method.error;
          }).toList();

          return shippingMethods;
        }
      }
      throw Exception('Failed to load shipping methods');
    } catch (e) {
      print('Error fetching shipping methods: $e');
      return [];
    }
  }
}
