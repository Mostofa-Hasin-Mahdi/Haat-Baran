import 'dart:convert';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:http/http.dart' as http;
import '../models/donation.dart';

class SslCommerzService {
  // Sandbox Credentials
  static const String _storeId = 'testbox';
  static const String _storePass = 'qwerty';
  static const String _sandboxUrl =
      'https://sandbox.sslcommerz.com/gwprocess/v4/api.php';

  static Future<String?> initiatePayment(
    Donation donation,
    double amount,
  ) async {
    try {
      // CORS Bypass for Flutter Web (Development Only)
      final url = kIsWeb
          ? 'https://corsproxy.io/?${Uri.encodeComponent(_sandboxUrl)}'
          : _sandboxUrl;

      final response = await http.post(
        Uri.parse(url),
        body: {
          'store_id': _storeId,
          'store_passwd': _storePass,
          'total_amount': amount.toString(),
          'currency': 'BDT',
          'tran_id':
              'txn_${donation.id}_${DateTime.now().millisecondsSinceEpoch}',
          'success_url': 'https://sandbox.sslcommerz.com/success',
          'fail_url': 'https://sandbox.sslcommerz.com/fail',
          'cancel_url': 'https://sandbox.sslcommerz.com/cancel',
          'cus_name': 'Test Customer',
          'cus_email': 'test@example.com',
          'cus_add1': 'Dhaka',
          'cus_add2': 'Dhaka',
          'cus_city': 'Dhaka',
          'cus_state': 'Dhaka',
          'cus_postcode': '1000',
          'cus_country': 'Bangladesh',
          'cus_phone': '01711111111',
          'cus_fax': '01711111111',
          'ship_name': 'Test Customer',
          'ship_add1': 'Dhaka',
          'ship_add2': 'Dhaka',
          'ship_city': 'Dhaka',
          'ship_state': 'Dhaka',
          'ship_postcode': '1000',
          'ship_country': 'Bangladesh',
          'shipping_method': 'NO',
          'product_name': 'Donation',
          'product_category': 'General',
          'product_profile': 'general',
          'num_of_item': '1',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['status'] == 'SUCCESS') {
          return json['GatewayPageURL'];
        } else {
          print('SSLCommerz Error: ${json['failedreason']}');
          return null;
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Payment Initiation Error: $e');
      return null;
    }
  }
}
