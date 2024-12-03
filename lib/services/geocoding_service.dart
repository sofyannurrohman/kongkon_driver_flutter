import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  final String apiKey = "AIzaSyChh_eCOsgZEydvhnMZdSY9F6L0RFyTyi0";

  Future<String?> getFormattedAddress(double latitude, double longitude) async {
    final url =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == "OK" && data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'];
        } else {
          throw Exception("Geocoding failed: ${data['status']}");
        }
      } else {
        throw Exception("Failed to fetch data: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching geocoding data: $error");
      return null;
    }
  }
}
