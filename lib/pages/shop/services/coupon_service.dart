import 'package:dio/dio.dart';
import '../models/coupon.dart';
import 'package:rc168/main.dart';

class CouponService {
  final Dio dio;

  CouponService(this.dio);

  Future<List<Coupon>> fetchAvailableCoupons() async {
    try {
      final response = await dio
          .get('${appUri}/gws_appcoupon/getAvailableCoupons&api_key=${apiKey}');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['message'][0]['msg_status'] == true) {
          return (data['coupons'] as List)
              .map((coupon) => Coupon.fromJson(coupon))
              .where((coupon) => coupon.status == 'Enabled')
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching coupons: $e');
      return [];
    }
  }
}
