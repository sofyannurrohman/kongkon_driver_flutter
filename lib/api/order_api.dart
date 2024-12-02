import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Order {
  
  Future<Map<String, dynamic>> fetchOrderDetails(String orderId) async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:3333/api/v1/orders/$orderId'));

      if (response.statusCode == 200) {
        // Decode the response body
        final responseData = jsonDecode(response.body);

        // Log the response to inspect its structure

        // Check if the response contains the 'data' and 'order' keys
        if (responseData['status'] == 'success' &&
            responseData['data'] != null) {
          final order = responseData['data']['order'];

          // Extract customer_id and merchant_id from the order data
          final customerId = order['customer_id'];
          final merchantId = order['merchant_id'];
          // If customerId or merchantId is null, handle the error or return early
          if (customerId == null || merchantId == null) {
            throw Exception('Missing user or merchant ID in the order data.');
          }

          return order; // Return the order data if everything is fine
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
          .get(Uri.parse('http://localhost:3333/api/v1/users/$userId'));

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
          .get(Uri.parse('http://localhost:3333/api/v1/merchants/$merchantId'));

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
        Uri.parse('http://localhost:3333/api/v1/partner/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'orderId': int.parse(orderId),
          'status': status,
        }),
      );
    print(response.body);
      if (response.statusCode == 201) {
        // Successfully updated status
        return; // No need to throw an exception here, handle success in the UI
      } else {
        throw Exception('Failed to update status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
Future<void> markOrderCompleted(String orderId) async {
  final response = await http.post(
    Uri.parse('http://localhost:3333/api/v1/orders/$orderId/completed'),
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 201) {
    // Successfully marked as completed

    // Step 1: Remove the order ID from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('currentOrderId'); // Remove saved order ID from SharedPreferences

  } else {
    // If the request fails, handle the error
    throw Exception('Failed to complete the order');
  }
}

}
