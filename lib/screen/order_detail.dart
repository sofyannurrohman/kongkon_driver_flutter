import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kongkon_app_driver/api/order_api.dart';
import 'package:kongkon_app_driver/services/geocoding_service.dart';
import 'package:kongkon_app_driver/shared/theme.dart';
import 'package:provider/provider.dart';

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
  bool isLoading = true;
  String errorMessage = '';
  late GoogleMapController _mapController;
  String selectedStatus = 'Pending';

  final Order orderApi = Order(); // Instantiate the Order API

  String? merchant_address;
  String? customer_address;
  @override
  void initState() {
    super.initState();
    fetchOrderDetails();
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
        print("Fetched Merchant address: $merchant_address");
      }).catchError((err) {
        print("Error fetching address: $err");
      });
      locationProvider.fetchHumanReadableAddress(c_lat, c_long).then((_) {
        setState(() {
          customer_address = locationProvider.address;
        });
        print("Fetched address: $customer_address");
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
      await orderApi.updateStatus(widget.orderId, selectedStatus);

      if (selectedStatus == 'completed') {
        await orderApi.markOrderCompleted(widget.orderId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order completed successfully!')),
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
        title: Text(
          'Order Details ${orderDetails?['id']}',
          style: blackTextStyle.copyWith(fontSize: 20, fontWeight: semibold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : orderDetails == null
                  ? const Center(child: Text('Failed to load order details.'))
                  : Column(
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          width: double.infinity,
                          child: GoogleMap(
                            onMapCreated: (controller) {
                              _mapController = controller;
                              if (merchantLocation != null) {
                                _mapController.moveCamera(
                                  CameraUpdate.newLatLngZoom(
                                      merchantLocation!, 18),
                                );
                              }
                            },
                            initialCameraPosition: CameraPosition(
                              target: merchantLocation ?? const LatLng(0, 0),
                              zoom: 18.0,
                            ),
                            markers: {
                              if (merchantLocation != null)
                                Marker(
                                  markerId: const MarkerId('merchant'),
                                  position: merchantLocation!,
                                  infoWindow: InfoWindow(
                                    title: 'Merchant Location',
                                    snippet: orderDetails?['merchant_id'],
                                  ),
                                ),
                              if (customerLocation != null)
                                Marker(
                                  markerId: const MarkerId('customer'),
                                  position: customerLocation!,
                                  infoWindow: InfoWindow(
                                    title: 'Customer Location',
                                    snippet: userDetails?['name'],
                                  ),
                                ),
                            },
                          ),
                        ),
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
                                        Text('${userDetails?['name']}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${customer_address}',
                                          style: blackTextStyle.copyWith(
                                              fontSize: 12, fontWeight: medium),
                                          maxLines: 3, // Limit to 4 lines
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Text('${userDetails?['phone_number']}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                        Text(
                                            'Rp.${orderDetails?['total_amount']}',
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
                                        Text('${merchantDetails?['name']}',
                                            style: blackTextStyle.copyWith(
                                                fontSize: 14,
                                                fontWeight: medium)),
                                        const SizedBox(height: 5),
                                        Text(
                                          '${merchant_address}',
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
                                  'Status saat ini: ${orderDetails?['status']}',
                                  style: blackTextStyle.copyWith(
                                      fontSize: 14, fontWeight: medium)),
                              const SizedBox(height: 5),
                              Text('Update status order',
                                  style: blackTextStyle.copyWith(
                                      fontSize: 14, fontWeight: semibold)),
                              DropdownButton<String>(
                                style: blackTextStyle.copyWith(
                                    fontSize: 14, fontWeight: light),
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
                              const SizedBox(height: 10),
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
