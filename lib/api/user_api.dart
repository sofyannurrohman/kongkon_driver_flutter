import 'dart:convert';
import 'package:http/http.dart' as http;

class User {
  
  Future<Map<String, dynamic>> registerUser(data) async {
    try {
      final response = await http
          .post(Uri.parse('http://192.168.1.35:3333/api/v1/register'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final order = responseData['data']['order'];

          final customerId = order['customer_id'];
          final merchantId = order['merchant_id'];
          if (customerId == null || merchantId == null) {
            throw Exception('Missing user or merchant ID in the order data.');
          }

          return order;
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception(
            'Failed to load order details, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching order details: $e');
      throw Exception('Error fetching order details');
    }
  }


}
