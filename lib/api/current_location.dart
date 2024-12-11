import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kongkon_app_driver/services/location_service.dart';

class LocationToggleProvider extends ChangeNotifier {
  bool _isToggleActive = false;
  Timer? _timer;
  String? _userId; // Set the user ID when initializing

   bool get isToggleActive => _isToggleActive;


  void setUserId(String userId) {
    _userId = userId;
  }

  

  Future<void> _updateCurrentLocation() async {
    try {
      if (_userId != null) {
        final location = await _getCurrentLocation();
        await LocationService.updateLocation(
          userId: _userId!,
          latitude: location['latitude']!,
          longitude: location['longitude']!,
        );
        debugPrint('Location updated');
      }
    } catch (e) {
      debugPrint('Failed to update location: $e');
    }
  }

  Future<Map<String, double>> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        return Future.error('Location permissions are denied');
      }
    }
if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  
}
