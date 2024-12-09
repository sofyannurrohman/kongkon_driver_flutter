import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final String _baseUrl = "http://192.168.18.25:3333/api/v1";
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  String? _userId;
  String? _token;
  Map<String, dynamic>? _userData;
  bool _isLoading = false;

  String? get userId => _userId;
  String? get accessToken => _token;
  Map<String, dynamic>? get userData => _userData;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
  _isLoading = true;
  notifyListeners();

  try {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Access user_id and access_token inside 'data'
      _userId = data['data']['user_id'];
      _token = data['data']['access_token'];

      print("Token: $_token");
      print("User ID: $_userId");

      // Save token and user ID to secure storage
      await _storage.write(key: 'access_token', value: _token);
      await _storage.write(key: 'user_id', value: _userId);

      await loadUserData(); // Fetch user data after login
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  } catch (e) {
    print("Login Error: $e");
    _isLoading = false;
    notifyListeners();
    return false;
  }
}

  Future<void> loadUserData() async {
    final token = await _storage.read(key: 'access_token');
    final userId = await _storage.read(key: 'user_id');
    if (token == null || userId == null) {
      print("No token or user ID found!");
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
         _userData = data['data'];
        notifyListeners();
      } else {
        print("Failed to fetch user data: ${response.statusCode}");
      }
    } catch (e) {
      print("Load User Data Error: $e");
    }
  }

  Future<void> logout() async {
    _userId = null;
    _token = null;
    _userData = null;

    await _storage.deleteAll();
    notifyListeners();
  }
}
