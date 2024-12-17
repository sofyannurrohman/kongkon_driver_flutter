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
import 'package:kongkon_app_driver/widget/drawer.dart';
import 'package:provider/provider.dart';
import '../api/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _driverStatus = "Status kerja tidak aktif";
  bool isToggleActive = false;
  Timer? _timer;
  String endpoint =
      "http://192.168.18.25:3333/api/v1/partner/location/";
  final SocketService socketService = SocketService();
  String? _userId;
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

      // Set up order assignment callback
      socketService.orderAssignmentCallback =
          (String orderId, String message, List<String> responseOptions) {
        // Check if the widget is still mounted before trying to show the dialog
        if (mounted) {
          _showOrderDialog(context, orderId, message, responseOptions);
        }
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
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      locationProvider.fetchHumanReadableAddress(lat, long).then((_) {
        setState(() {
          address = locationProvider.address;
        });
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
      if (orderDetails['partner_id'] == _userId) {
        setState(() {
          _savedOrder = null;
        });
        return;
      }
      final merchantDetails =
          await orderApi.fetchMerchantDetails(orderDetails['merchant_id']);
      setState(() {
        _savedOrder = orderDetails;
        _savedMerchant = merchantDetails['data'];
        isToggleActive = true;
      });
      _handleToggle(isToggleActive);
      _fetchAddress();
    }
  }

  @override
  void dispose() {
    socketService.disconnect();
    _timer?.cancel();
    super.dispose();
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

  void _handleToggle(bool value) async {
    if (isToggleActive) {
      // Stop tracking
      setState(() {
        _driverStatus = 'Status kerja tidak aktif';
        isToggleActive = false;
      });
      _timer?.cancel();
      await LocationService.deleteLocation(userId: _userId);
      print('Location deleted and timer stopped');
    } else {
      Map<String, double> location = await _getCurrentLocation();
      await LocationService.updateLocation(
        userId: _userId!,
        latitude: location['latitude']!,
        longitude: location['longitude']!,
      );
      print(location);
      setState(() {
        _driverStatus = 'Status kerja aktif';
        isToggleActive = true;
      });

      if (_userId != null) {
        _timer = Timer.periodic(Duration(seconds: 120), (timer) async {
          print('Location periodically updated');
          if (isToggleActive) {
            Map<String, double> location = await _getCurrentLocation();
            await LocationService.updateLocation(
              userId: _userId!,
              latitude: location['latitude']!,
              longitude: location['longitude']!,
            );
          } else {
            timer.cancel();
            _timer = null;
            print('Timer stopped');
          }
        });
      }
    }
  }

  void _showOrderDialog(BuildContext parentContext, String orderId,
      String message, List<String> responseOptions) {
    _handleToggle(isToggleActive);
    if (!mounted) return;

    print("Showing order dialog for order: $orderId");

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
                onPressed: () async {
                  final orderDetails =
                      await orderApi.fetchOrderDetails(orderId);
                  final merchantDetails = await orderApi
                      .fetchMerchantDetails(orderDetails['merchant_id']);

                  setState(() {
                    _savedOrder = orderDetails;
                    _savedMerchant = merchantDetails['data'];
                  });

                  _fetchAddress();
                  // Handle "accept" response
                  final socketService =
                      Provider.of<SocketService>(parentContext, listen: false);
                  socketService.handleResponse('accepted');
                  // Close the dialog
                  Navigator.pop(dialogContext);
                  // Navigate to the OrderDetailPage
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (context) => OrderDetailPage(orderId: orderId),
                    ),
                  );
                },
                child: Text(
                  'Terima',
                  style: blackTextStyle.copyWith(
                      fontSize: 14, fontWeight: semibold),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Handle "decline" response
                  final socketService =
                      Provider.of<SocketService>(parentContext, listen: false);
                  socketService.handleResponse('declined');

                  // Close the dialog without navigation
                  Navigator.pop(parentContext);
                },
                child: Text(
                  'Tolak',
                  style: blackTextStyle.copyWith(
                      fontSize: 14, fontWeight: semibold),
                ),
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
            Builder(builder: (context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).openDrawer();
                },
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: (authProvider
                                  .userData?['avatar_file_name'] !=
                              null &&
                          authProvider.userData?['avatar_file_name'] != '')
                      ? NetworkImage(
                          'http://192.168.18.25:3333/uploads/avatars/${authProvider.userData?['avatar_file_name']}')
                      : null, // No image, so don't set a background image
                  backgroundColor: (authProvider
                                  .userData?['avatar_file_name'] ==
                              null ||
                          authProvider.userData?['avatar_file_name'] == '')
                      ? Colors.grey // Grey circle if no avatar
                      : null, // Default transparent background when there's an avatar
                  child: (authProvider.userData?['avatar_file_name'] == null ||
                          authProvider.userData?['avatar_file_name'] == '')
                      ? Icon(
                          Icons.person, // Person icon when no avatar
                          color: Colors.white, // White color for the icon
                          size: 20, // Icon size to fit within the CircleAvatar
                        )
                      : null, // If avatar exists, no child is needed
                ),
              );
            }),
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
      drawer: DrawerWidget(
          authProvider: authProvider,
          userId: authProvider.userData?['id'],
          avatar_file_name: authProvider.userData?['avatar_file_name'],
          name: authProvider.userData?['name'],
          license: authProvider.userData?['license_number']),
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
                              const SizedBox(height: 10),
                              Text(
                                "${address} ",
                                style: blackTextStyle.copyWith(
                                  fontSize: 12,
                                  fontWeight: regular,
                                ),
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
          if (_savedOrder == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (!isToggleActive) {
                      _handleToggle(!isToggleActive);
                    } else if (isToggleActive) {
                      _handleToggle(isToggleActive);
                    }
                  },
                  icon: const Icon(color: kWhiteColor, Icons.arrow_forward),
                  label: Text("Mulai Bekerja",
                      style: whiteTextStyle.copyWith(
                          fontSize: 16, fontWeight: semibold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isToggleActive ? kPrimaryColor : kGreyColor,
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
