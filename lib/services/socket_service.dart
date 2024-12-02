import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';

class SocketService extends ChangeNotifier {
  IO.Socket? _socket;
  String? userId;
  String _driverStatus = 'Available'; 
String? _currentOrderId; // Track the current order ID

  String get driverStatus => _driverStatus;
  // Callback function to notify UI about order assignments
  Function? orderAssignmentCallback;

  IO.Socket? get socket => _socket;

  // Constructor to initialize the userId and connect to the socket
  void connect(String userId) {
    this.userId = userId;

    if (_socket == null) {
      // Set up socket connection options
      _socket = IO.io('http://localhost:3333', <String, dynamic>{
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
    }
  }

 void _handleOrderAssignment(Map<String, dynamic> data) async {
  try {
    if (!data.containsKey('orderId') || !data.containsKey('message') || !data.containsKey('responseOptions')) {
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

 // New: Handle driver response
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

    // Update state
    _driverStatus = response == 'accepted' ? 'On Duty' : 'Available';
    _currentOrderId = null; // Clear the current order ID
    notifyListeners(); // Notify UI of state changes
  }

  // Disconnect the socket when it's no longer needed
  void disconnect() {
    _socket?.disconnect();
    print('Socket disconnected');
  }
}
