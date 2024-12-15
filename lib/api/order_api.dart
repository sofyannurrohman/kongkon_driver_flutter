import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Order {
  
  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    try {
      final response = await http
          .get(Uri.parse('https://b0be-116-12-47-61.ngrok-free.app/api/v1/orders/$orderId'));

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

  Future<Map<String, dynamic>> fetchUserDetails(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('https://b0be-116-12-47-61.ngrok-free.app/api/v1/users/$userId'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      print('Error fetching user details: $e');
      throw Exception('Error fetching user details');
    }
  }

  Future<Map<String, dynamic>> fetchMerchantDetails(String merchantId) async {
    try {
      final response = await http
          .get(Uri.parse('https://b0be-116-12-47-61.ngrok-free.app/api/v1/merchants/$merchantId'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load merchant details');
      }
    } catch (e) {
      print('Error fetching merchant details: $e');
      throw Exception('Error fetching merchant details');
    }
  }

  Future<void> updateStatus(String orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://b0be-116-12-47-61.ngrok-free.app/api/v1/partner/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': int.parse(orderId),
          'status': status,
        }),
      );
    print(response.body);
      if (response.statusCode == 201) {
        // Successfully updated status
        return; } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
Future<void> markOrderCompleted(String orderId) async {
  final response = await http.post(
    Uri.parse('https://b0be-116-12-47-61.ngrok-free.app/api/v1/orders/$orderId/completed'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 201) {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('currentOrderId');
  } else {
    throw Exception('Failed to complete the order');
  }
}
Future<void> markOrderCanceled(String orderId) async {
  final response = await http.post(
    Uri.parse('https://b0be-116-12-47-61.ngrok-free.app/api/v1/orders/$orderId/cancel'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('currentOrderId');
  } else {
    throw Exception('Failed to complete the order');
  }
}
}
