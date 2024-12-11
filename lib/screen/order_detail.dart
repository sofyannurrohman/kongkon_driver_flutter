import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kongkon_app_driver/api/order_api.dart';
import 'package:kongkon_app_driver/services/geocoding_service.dart';
import 'package:kongkon_app_driver/services/socket_service.dart';
import 'package:kongkon_app_driver/shared/theme.dart';
import 'package:kongkon_app_driver/widget/maps.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({Key? key, required this.orderId}) : super(key: key);
  @override
  _OrderDetailPageState createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? orderDetails;
  Map<String, dynamic>? userDetails;
  Map<String, dynamic>? merchantDetails;
  LatLng? merchantLocation;
  LatLng? customerLocation;
  Map<String, double>? currentLocation;
  bool isLoading = true;
  String errorMessage = '';
  // late GoogleMapController _mapController;
  String? selectedStatus = 'Pending';
  bool isUpdatingLocation = false;
  Timer? locationUpdateTimer;
  final Order orderApi = Order();
  String? merchant_address;
  String? customer_address;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchOrderDetails();
    });
  }

  @override
  void dispose() {
    locationUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchOrderDetails() async {
    try {
      // Fetch the order details first
      final orderResponse = await orderApi.fetchOrderDetails(widget.orderId);

      setState(() {
        orderDetails =
            orderResponse; // Store the full order details in the state
        isLoading = false;
      });

      // Extract the user_id and merchant_id from the order
      final String? userId = orderDetails?['customer_id'];
      final String? merchantId = orderDetails?['merchant_id'];
      if (userId == null || merchantId == null) {
        throw Exception('User or Merchant ID is missing');
      }
      if (userId != null && merchantId != null) {
        // Fetch user and merchant details if the ids are not null
        final userResponse = await orderApi.fetchUserDetails(userId);
        final merchantResponse =
            await orderApi.fetchMerchantDetails(merchantId);

        setState(() {
          userDetails = userResponse['data'];
          merchantDetails = merchantResponse['data'];
        });
      } else {
        throw Exception('User or Merchant ID is missing');
      }

      // Extract coordinates for the map markers
      final fromCoordinates = orderDetails?['from_location']['coordinates'];
      final toCoordinates = orderDetails?['to_location']['coordinates'];
      setState(() {
        merchantLocation = LatLng(fromCoordinates[1], fromCoordinates[0]);
        customerLocation = LatLng(toCoordinates[1], toCoordinates[0]);
      });

      _startLocationUpdates(merchantLocation!, customerLocation!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchAddress();
      });
    } catch (e) {
      setState(() {
        errorMessage =
            e.toString(); // Show error message if something goes wrong
        isLoading = false;
      });
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

  void _startLocationUpdates(
      LatLng merchantLocation, LatLng customerLocation) async {
    final socketService = Provider.of<SocketService>(context, listen: false);
    LatLng? mockDriverLocation; // To track the driver's mock location
    const double stepSize = 0.001; // Adjust step size for movement
    bool headingToMerchant = true; // State to determine the current destination

    locationUpdateTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      try {
        if (mockDriverLocation == null) {
          // Initialize mock location with the driver's current location
          final location = await _getCurrentLocation();
          mockDriverLocation =
              LatLng(location['latitude']!, location['longitude']!);
        } else {
          // Determine the current target destination
          final LatLng targetLocation =
              headingToMerchant ? merchantLocation : customerLocation;

          // Calculate the direction (bearing) towards the current target
          final double deltaLat =
              targetLocation.latitude - mockDriverLocation!.latitude;
          final double deltaLng =
              targetLocation.longitude - mockDriverLocation!.longitude;
          final double angle = atan2(deltaLng, deltaLat);

          // Update mock location towards the current target
          final double nextLat =
              mockDriverLocation!.latitude + stepSize * cos(angle);
          final double nextLng =
              mockDriverLocation!.longitude + stepSize * sin(angle);

          mockDriverLocation = LatLng(nextLat, nextLng);

          // Check if the driver has reached the target
          if ((deltaLat.abs() < stepSize) && (deltaLng.abs() < stepSize)) {
            if (headingToMerchant) {
              print('Driver has reached the merchant location.');
              headingToMerchant = false; // Switch to heading to the customer
            } else {
              print('Driver has reached the customer location.');
              timer
                  .cancel(); // Stop the timer if the final destination is reached
            }
          }
        }

        // Emit the driver's location via socket
        String? driverId = orderDetails?['partner_id'];
        if (driverId != null && mockDriverLocation != null) {
          socketService.emitDriverLocation(
            driverId,
            mockDriverLocation!.latitude,
            mockDriverLocation!.longitude,
          );
          print(
              'Driver location emitted: {driverId: $driverId, lat: ${mockDriverLocation!.latitude}, lng: ${mockDriverLocation!.longitude}}');
        }

        // Update the map marker and UI
        setState(() {
          currentLocation = {
            'latitude': mockDriverLocation!.latitude,
            'longitude': mockDriverLocation!.longitude
          };
        });
      } catch (e) {
        print('Error updating location: $e');
      }
    });
  }

  void _fetchAddress() {
    if (orderDetails != null) {
      final m_lat = orderDetails?['from_location']['coordinates'][1];
      final m_long = orderDetails?['from_location']['coordinates'][0];
      final c_lat = orderDetails?['to_location']['coordinates'][1];
      final c_long = orderDetails?['to_location']['coordinates'][0];
      final locationProvider =
          Provider.of<LocationProvider>(context, listen: false);
      locationProvider.fetchHumanReadableAddress(m_lat, m_long).then((_) {
        if (locationProvider.address == null) {
          print("Error: Address not found for the given coordinates.");
        } else {
          setState(() {
            merchant_address = locationProvider.address;
          });
        }
      });
      locationProvider.fetchHumanReadableAddress(c_lat, c_long).then((_) {
        setState(() {
          customer_address = locationProvider.address;
        });
      }).catchError((err) {
        print("Error fetching address: $err");
      });
    } else {
      print("No saved order to fetch address for.");
    }
  }

  Future<void> updateStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      await orderApi.updateStatus(widget.orderId, selectedStatus!);

      if (selectedStatus == 'completed') {
        await orderApi.markOrderCompleted(widget.orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order completed successfully!')),
        );

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (selectedStatus == 'canceled') {
         await orderApi.markOrderCompleted(widget.orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order has been cancelled')),
        );

        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: Text(
          'Order Details ${orderDetails?['id'] ?? 'Loading...'}',
          style: whiteTextStyle.copyWith(fontSize: 20, fontWeight: semibold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : (orderDetails == null ||
                      userDetails == null ||
                      merchantDetails == null)
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    
                      children: [
                        MapContainer(
                            merchantLocation: merchantLocation!,
                            customerLocation: customerLocation!,
                            orderDetails: orderDetails!,
                            userDetails: userDetails!,
                            currentLocation: LatLng(
                                currentLocation?['latitude']! ?? 0,
                                currentLocation?['longitude']! ?? 0)),
                        Container(
                          width:
                              400, // Makes the container fill the width of its parent
                          height: 400,
                          decoration: BoxDecoration(
                            color: Colors
                                .white, // Set your container background color here
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(
                                  16.0), // Set the desired radius
                              topRight: Radius.circular(16.0),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceEvenly, // Ensures equal spacing
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Customer detail :',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: semibold)),
                                        const SizedBox(height: 10),
                                        Text(
                                            '${userDetails?['name'] ?? '...Loading'}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${customer_address ?? '...Loading'}',
                                          style: blackTextStyle.copyWith(
                                              fontSize: 12, fontWeight: medium),
                                          maxLines: 3, // Limit to 4 lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                            '${userDetails?['phone_number'] ?? '...Loading'}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                        Text(
                                            'Rp.${orderDetails?['total_amount'] ?? '...Loading'}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Merchant Detail:',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: semibold)),
                                        const SizedBox(height: 10),
                                        Text(
                                            '${merchantDetails?['name'] ?? '...Loading'}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${merchant_address ?? '...Loading'}',
                                          style: blackTextStyle.copyWith(
                                            fontSize: 12,
                                            fontWeight: medium,
                                          ),
                                          maxLines: 3, // Limit to 4 lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                          width: 20,
                                        )
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                  'Status saat ini: ${selectedStatus ?? '...Loading'}',
                                  style: blackTextStyle.copyWith(
                                      fontSize: 14, fontWeight: medium)),
                              const SizedBox(height: 5),
                              Text('Update status order',
                                  style: blackTextStyle.copyWith(
                                      fontSize: 12, fontWeight: semibold)),
                              DropdownButton<String>(
                                style: blackTextStyle.copyWith(
                                    fontSize: 10, fontWeight: light),
                                value: selectedStatus,
                                onChanged: (String? newStatus) {
                                  setState(() {
                                    selectedStatus = newStatus!;
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: 'Pending',
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Menuju merchant',
                                    child: Text('Menuju merchant'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Pesanan sedang diantar ke tujuan',
                                    child: Text(
                                        'Pesanan sedang diantar ke tujuan'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'completed',
                                    child: Text(
                                        'Pesanan sedang sudah diterima customer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'canceled',
                                    child: Text('Canceled'),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  updateStatus();
                                },
                                icon: const Icon(
                                    color: kWhiteColor, Icons.account_circle),
                                label: Text("Update Status Orderan",
                                    style: whiteTextStyle.copyWith(
                                        fontSize: 16, fontWeight: semibold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(defaultRadius),
                                  ),
                                  minimumSize: const Size(60, 60),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
