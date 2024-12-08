import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocationProvider with ChangeNotifier {
  String? _address;
  bool _isLoading = false;

  String? get address => _address;
  bool get isLoading => _isLoading;

  Future<void> fetchHumanReadableAddress(
      double latitude, double longitude) async {
    _isLoading = true;
    notifyListeners();

    try {
      final apiKey =
          'AIzaSyChh_eCOsgZEydvhnMZdSY9F6L0RFyTyi0'; // Replace with your API key
      final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK') {
          _address = data['results'][0]['formatted_address'];
        } else {
          _address = 'Failed to reverse geocode: ${data['status']}';
        }
      } else {
        _address = 'Failed to fetch address';
      }
    } catch (e) {
      _address = 'Error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
