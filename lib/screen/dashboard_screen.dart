import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kongkon_app_driver/api/order_api.dart';
import 'package:kongkon_app_driver/screen/order_detail.dart';
import 'package:kongkon_app_driver/services/geocoding_service.dart';
import 'package:kongkon_app_driver/services/location_service.dart';
import 'package:kongkon_app_driver/services/socket_service.dart';
import 'package:kongkon_app_driver/shared/theme.dart';
import 'package:provider/provider.dart';
import '../api/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _driverStatus = "Work status inactive";
  bool isToggleActive = false;
  Timer? _timer;
  String endpoint = "http://localhost:3333/api/v1/partner/location/";

  String? _userId;
  String? _currentOrderId;
  Map<String, dynamic>? _savedOrder;
  Map<String, dynamic>? _savedMerchant;

  // API Services
  final Order orderApi = Order();
  final GeocodingService geocodingService = GeocodingService();

  // Merchant Location Details
  String? address;
  String? error;



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
    fetchAddress();
  }

  Future<void> fetchSavedOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrderId = prefs.getString('currentOrderId');

    if (savedOrderId != null) {
      final orderDetails =
          await orderApi.fetchOrderDetails(savedOrderId.toString());
      final merchantDetails =
          await orderApi.fetchMerchantDetails(orderDetails['merchant_id']);
      setState(() {
        _savedOrder = orderDetails;
        _savedMerchant = merchantDetails['data'];
      });
    }
  }


Future<void> fetchAddress() async {
  try {
    if (_savedMerchant != null) {
      // Log merchant details for debugging
      print("Saved Merchant: $_savedMerchant");

      final location = _savedMerchant?['location'];
      if (location != null && location['coordinates'] != null) {
        final List coordinates = location['coordinates'];

        // Check if coordinates are valid
        if (coordinates.length >= 2) {
          final double longitude = coordinates[0];
          final double latitude = coordinates[1];

          // Log coordinates for debugging
          print("Coordinates: Latitude = $latitude, Longitude = $longitude");

          final formattedAddress =
              await geocodingService.getFormattedAddress(latitude, longitude);

          setState(() {
            address = formattedAddress;
            error = null; // Clear any errors
          });
        } else {
          setState(() {
            error = "Invalid coordinates received.";
          });
        }
      } else {
        setState(() {
          error = "Location data is missing or incomplete.";
        });
      }
    } else {
      setState(() {
        error = "No merchant data available.";
      });
    }
  } catch (e) {
    setState(() {
      error = e.toString(); // Capture and display the error
    });
    print("Error fetching address: $e");
  }
}

  @override
  void dispose() {
    Provider.of<SocketService>(context, listen: false).disconnect();
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, double>> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }

  void _handleToggle(bool value) {
    setState(() {
      isToggleActive = value;
    });

    if (isToggleActive && _userId != null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        Map<String, double> location = await _getCurrentLocation();
        await LocationService.updateLocation(
          userId: _userId!,
          latitude: location['latitude']!,
          longitude: location['longitude']!,
        );
      });
    } else {
      _timer?.cancel();
    }
  }

  void _showOrderDialog(BuildContext parentContext, String orderId,
      String message, List<String> responseOptions) {
    showDialog(
      context: parentContext, // Use parent context
      builder: (context) {
        return AlertDialog(
          title: Text('Mendapat Orderan Baru'),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF6200EE),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(
                  authProvider.userData?['avatarUrl'] ??
                      'https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  authProvider.userData?['name'] ?? 'Fufu Fafa',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                Text(
                  _driverStatus,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: const [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 4),
                Text("4.9", style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_savedOrder != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('spoon.png'))),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Order ${_savedOrder?['id']}",
                              style: blackTextStyle.copyWith(
                                  fontSize: 18, fontWeight: medium)),
                          const SizedBox(height: 8),
                          Text("${_savedMerchant?['name']} ",
                              style: blackTextStyle.copyWith(
                                  fontSize: 18, fontWeight: medium)),
                          const SizedBox(height: 4),
                          Text(
                            "${address}",
                            style: blackTextStyle.copyWith(
                                fontSize: 18, fontWeight: medium),
                          ),
                          const SizedBox(height: 4),
                          Text("${_savedOrder?['totalAmount']}",
                              style: blackTextStyle.copyWith(
                                  fontSize: 18, fontWeight: medium)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to the order detail page when tapped
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrderDetailPage(
                                      orderId: _savedOrder!['id'].toString()),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF6200EE),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                                style: whiteTextStyle.copyWith(
                                    fontSize: 18, fontWeight: medium),
                                "View Order Details"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const Expanded(
            child: Center(
              child: Text(
                'Belum ada orderan yang masuk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                _handleToggle(!isToggleActive);
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text("Start Working"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isToggleActive ? Colors.green : Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
