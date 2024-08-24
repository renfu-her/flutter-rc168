import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rc168/main.dart';

class PaymentService {
  final Dio dio;

  PaymentService(this.dio);

  Future<List<DropdownMenuItem<String>>> fetchPaymentMethods(
      String customerId) async {
    try {
      final response = await dio.get(
          '${appUri}/gws_apppayment_methods/index&customer_id=${customerId}&api_key=${apiKey}');

      if (response.statusCode == 200) {
        final data = response.data;
        final paymentMethods = data['payment_methods'] as List;

        return paymentMethods.map((method) {
          return DropdownMenuItem<String>(
            value: method['code'],
            child: Text(method['title']),
          );
        }).toList();
      }
      throw Exception('Failed to load payment methods');
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }
}
