import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAddress();
    });
  }

  void _fetchAddress() {
    if (_savedOrder != null) {
      final lat = _savedOrder?['from_location']['coordinates'][1];
      final long = _savedOrder?['from_location']['coordinates'][0];
      print("Fetching address for coordinates: $lat, $long");

      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);

      locationProvider.fetchHumanReadableAddress(lat, long).then((_) {
        setState(() {
          address = locationProvider.address;
        });
        print("Fetched address: $address");
      }).catchError((err) {
        print("Error fetching address: $err");
      });
    } else {
      print("No saved order to fetch address for.");
    }
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
      _fetchAddress();
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
      barrierDismissible: false,
      context: parentContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
            title: Text(
                style:
                    blackTextStyle.copyWith(fontSize: 14, fontWeight: medium),
                'Mendapat Orderan Baru'),
            content: Text(
                style:
                    blackTextStyle.copyWith(fontSize: 14, fontWeight: medium),
                message),
            actions: [
              TextButton(
                onPressed: () {
                  // Handle "accept" response
                  final socketService =
                      Provider.of<SocketService>(context, listen: false);
                  socketService.handleResponse('accepted');

                  // Navigate to the OrderDetailPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailPage(orderId: orderId),
                    ),
                  );
                },
                child: Text('Accept'),
              ),
              TextButton(
                onPressed: () {
                  // Handle "decline" response
                  final socketService =
                      Provider.of<SocketService>(context, listen: false);
                  socketService.handleResponse('declined');

                  // Close the dialog without navigation
                  Navigator.pop(context);
                },
                child: Text('Decline'),
              ),
            ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.userData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Loading..."),
        ),
        body: const Center(child: CircularProgressIndicator()),
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
              backgroundImage: NetworkImage(authProvider
                          .userData?['avatar_file_name'] !=
                      null
                  ? 'http://192.168.18.25:3333/uploads/avatars/${authProvider.userData?['avatar_file_name']}'
                  : 'https://via.placeholder.com/150'),
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
            const Row(
              children: [
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
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Ensures alignment at the top
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('spoon.png'),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width: 16), // Space between image and text
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Text(
                                "${_savedMerchant?['name']} ",
                                style: blackTextStyle.copyWith(
                                  fontSize: 18,
                                  fontWeight: bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${address}',
                                style: blackTextStyle.copyWith(
                                  fontSize: 14,
                                  fontWeight: medium,
                                ),
                                maxLines: 4, // Limit to 4 lines
                                overflow: TextOverflow
                                    .ellipsis, // Add ellipsis for overflow
                              ),
                              const SizedBox(height: 4),
                              Text(
                                // "Rp.${_savedOrder?['partner_profit']}",
                                "Rp.${_savedOrder?['total_amount']}",
                                style: blackTextStyle.copyWith(
                                  fontSize: 18,
                                  fontWeight: medium,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                onPressed: () {
                                  // Navigate to the order detail page when tapped
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailPage(
                                        orderId: _savedOrder!['id'].toString(),
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  style: whiteTextStyle.copyWith(
                                    color: kGreyColor,
                                    fontSize: 16,
                                    fontWeight: light,
                                  ),
                                  "Lihat selengkapnya",
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ],
                    ))),
          if (_savedOrder == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('assets/illustration.png'))),
                    ),
                    Text(
                      'Belum ada orderan yang masuk',
                      style: blackTextStyle.copyWith(
                          fontSize: 16, fontWeight: semibold),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ElevatedButton.icon(
                onPressed: () {
                  _handleToggle(!isToggleActive);
                },
                icon: const Icon(color: kWhiteColor, Icons.arrow_forward),
                label: Text("Mulai Bekerja",
                    style: whiteTextStyle.copyWith(
                        fontSize: 16, fontWeight: semibold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isToggleActive ? kPrimaryColor : kGreyColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
