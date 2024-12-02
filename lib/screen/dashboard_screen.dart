import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kongkon_app_driver/api/order_api.dart';
import 'package:kongkon_app_driver/screen/order_detail.dart';
import 'package:kongkon_app_driver/services/location_service.dart';
import 'package:kongkon_app_driver/services/socket_service.dart';
import 'package:provider/provider.dart';
import '../api/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _driverStatus = "Available";
  bool isToggleActive = false;
  Timer? _timer;
  String endpoint = "http://localhost:3333/api/v1/partner/location/";

  String? _userId; // Make userId a state variable
  String? _currentOrderId;
  Map<String, dynamic>? _savedOrder;
  final Order orderApi = Order();

  Future<void> fetchSavedOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrderId = prefs.getString('currentOrderId');

    if (savedOrderId != null) {
      // Fetch order details from the server
      final orderDetails =
          await orderApi.fetchOrderDetails(savedOrderId.toString());
      // Update the UI with the fetched order details
      setState(() {
        _savedOrder = orderDetails;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.loadUserData();

    setState(() {
      _userId = authProvider.userData?['id'];
    });
    fetchSavedOrder();
    if (_userId != null) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.connect(_userId!);

      socketService.orderAssignmentCallback =
          (String orderId, String message, List<String> responseOptions) {
        _showOrderDialog(context, orderId, message, responseOptions);
      };
    }
  }

  @override
  void dispose() {
    Provider.of<SocketService>(context, listen: false).disconnect();
    _timer?.cancel();
    super.dispose();
  }

  // Function to get the driver's current location
  Future<Map<String, double>> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return {
      'latitude': 37.9421,
      'longitude': position.longitude,
    };
  }

  // Function to handle the toggle state
  void _handleToggle(bool value) {
    setState(() {
      isToggleActive = value;
    });

    if (isToggleActive && _userId != null) {
      // Start sending location every 1 minute
      _timer?.cancel(); // Ensure no duplicate timers
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        Map<String, double> location = await _getCurrentLocation();
        await LocationService.updateLocation(
          userId: _userId!, // Use the state variable _userId
          latitude: location['latitude']!,
          longitude: location['longitude']!,
        );
      });
    } else {
      // Stop sending location
      _timer?.cancel();
    }
  }

  void _showOrderDialog(BuildContext parentContext, String orderId,
      String message, List<String> responseOptions) {
    showDialog(
      context: parentContext, // Use parent context
      builder: (context) {
        return AlertDialog(
          title: Text('New Order Assigned'),
          content: Text(message),
          actions: responseOptions.map((option) {
            return TextButton(
              onPressed: () {
                final socketService =
                    Provider.of<SocketService>(context, listen: false);
                socketService.handleResponse(
                    option == 'accept' ? 'accepted' : 'declined');

                // Navigate to the order detail page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderDetailPage(orderId: orderId),
                  ),
                );
              },
              child: Text(option),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // Wait until user data is loaded
    if (authProvider.userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text("Loading..."),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

        print(_savedOrder);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        title: Text("Welcome, ${authProvider.userData?['name'] ?? 'Guest'}!"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      
      body: Column(
        children: [
          if (_savedOrder != null)
            Card(
              child: ListTile(
                title: Text("Order ID: ${_savedOrder!['id']}"),
                subtitle: Text("Order Details: ${_savedOrder!['merchant_id']}"),
                onTap: () {
                  // Navigate to the order detail page when tapped
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          OrderDetailPage(orderId: _savedOrder!['id'].toString()),
                    ),
                  );
                },
              ),
            ),
          const Center(
            child: Text('Waiting for new orders...'),
          ),
          const Text(
            "Toggle to start/stop sending location updates",
            textAlign: TextAlign.center,
          ),
          Switch(
            value: isToggleActive,
            onChanged: _handleToggle,
          ),
        ],
      ),
    );
  }
}
