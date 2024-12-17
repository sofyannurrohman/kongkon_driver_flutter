import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  String? userId;
  String _driverStatus = 'Available';
  String? _currentOrderId; // Track the current order ID
  Position? _currentPosition; // Store the current position
  bool _isTracking = false; // Track if location updates are ongoing
  StreamSubscription<Position>? _positionStream;

  String get driverStatus => _driverStatus;
  Position? get currentPosition => _currentPosition;

  // Callback function to notify UI about order assignments
  Function? orderAssignmentCallback;

  IO.Socket? get socket => _socket;

  // Constructor to initialize the userId and connect to the socket
  void connect(String userId) {
    this.userId = userId;

    if (_socket == null) {
      // Set up socket connection options
      _socket = IO.io('http://192.168.18.25:3333', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {'userId': userId}, // Send userId as query param
      });

      // Connect the socket
      _socket!.connect();

      // Listen for the connection event
      _socket!.on('connect', (_) {
        print('Socket connected');
      });

      // Listen for order assignments
      _socket!.on('orderAssignment', (data) {
        print('Received order assignment: $data');
        _handleOrderAssignment(data);
      });

      // Listen for driver response to ensure it's working
      _socket!.on('driverResponse', (data) {
        print('Driver response: $data');
      });
      _socket?.on('driverLocationUpdate', (data) {
        // Parse location data
        final lat = data['lat'] as double;
        final lng = data['lng'] as double;

        _currentPosition = Position(
          latitude: lat, longitude: lng,
          timestamp: DateTime.now(), // Add this line
          accuracy: 0.0,
          altitude: 0.0,
          altitudeAccuracy: 0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          headingAccuracy: 0,
        );
        notifyListeners(); // Notify UI to update
      });
    }
  }

  void _handleOrderAssignment(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('orderId') ||
          !data.containsKey('message') ||
          !data.containsKey('responseOptions')) {
        print('Invalid data received: $data');
        return;
      }

      // Extract order ID
      _currentOrderId = data['orderId'].toString();

      // Save the current order ID locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentOrderId', _currentOrderId!);

      // Notify UI via callback
      if (orderAssignmentCallback != null) {
        orderAssignmentCallback!(
          _currentOrderId!,
          data['message'],
          List<String>.from(data['responseOptions']),
        );
      } else {
        print('Order assignment callback not set');
      }
    } catch (e) {
      print('Error handling order assignment: $e');
    }
  }

  void handleResponse(String response) {
    if (_socket == null || !(_socket?.connected ?? false)) {
      print('Socket is not connected');
      return;
    }

    if (_currentOrderId == null) {
      print('No current order to respond to');
      return;
    }

    _socket?.emit(
      'driverResponse',
      {
        'driverId': userId,
        'orderId': _currentOrderId,
        'accepted': response == 'accepted',
        'declined': response == 'declined'
      },
    );

    print(response);
    // Update state
    _driverStatus = response == 'accepted' ? 'On Duty' : 'Available';
    _currentOrderId = null; // Clear the current order ID
    notifyListeners(); // Notify UI of state changes
  }

  // Start tracking driver's location
  Future<void> startTracking() async {
    if (_isTracking) return; // Prevent multiple tracking tasks
    _isTracking = true;

    // Check and request location permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    // Periodically update the location
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _socket?.emit('updateDriverLocation', {
        'driverId': userId,
        'lat': position.latitude + 0.0001, // Slight latitude change
        'lng': position.longitude + 0.0001, // Slight longitude change
      });
      print('>>>>>>>>>${_currentPosition}');
      notifyListeners();
    });
  }

  // Stop tracking driver's location
  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel(); // Cancel the listener
    _positionStream = null;
    _currentPosition = null;
  }

  // Disconnect the socket when it's no longer needed
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    print('Socket disconnected');
  }

  void emitDriverLocation(int orderId,String driverId, double lat, double lng,String customerId) {
    socket?.emit('updateDriverLocation', {
      'orderId': orderId,
      'driverId': driverId,
      'lat': lat,
      'lng': lng,
      'customerId': customerId
    });
    print(
        'Driver location emitted: {driverId: $driverId, lat: $lat, lng: $lng}');
  }
}
