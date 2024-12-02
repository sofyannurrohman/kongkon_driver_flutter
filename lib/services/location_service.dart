import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {

  static Future<void> updateLocation({
    required String userId,
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.parse('http://localhost:3333/api/v1/partner/location/$userId');
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      print(response);
    } catch (e) {
      print("Error while sending location: $e");
    }
  }
}