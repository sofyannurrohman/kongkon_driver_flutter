import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kongkon_app_driver/api/order_api.dart';

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
    } catch (e) {
      setState(() {
        errorMessage =
            e.toString(); // Show error message if something goes wrong
        isLoading = false;
      });
    }
  }

  Future<void> updateStatus() async {
    setState(() {
      isLoading = true;
    });

    try {
      await orderApi.updateStatus(widget.orderId, selectedStatus);

     if (selectedStatus == 'Order has been sent to customer') {
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
        title: const Text('Order Details'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text('Error: $errorMessage'))
              : orderDetails == null
                  ? const Center(child: Text('Failed to load order details.'))
                  : Column(
                      children: [
                        // Google Map wrapped in a responsive container
                        Container(
                          height: MediaQuery.of(context).size.height *
                              0.4, // 40% of the screen height
                          width: double.infinity, // Full width of the container
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
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID: ${orderDetails?['id']}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Customer: \$${userDetails?['name']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Total Amount: \$${orderDetails?['total_amount']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Status: ${orderDetails?['status']}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              const Text('Select Status'),
                              DropdownButton<String>(
                                value: selectedStatus,
                                onChanged: (String? newStatus) {
                                  setState(() {
                                    selectedStatus = newStatus!;
                                  });
                                },
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Pending',
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'In Progress',
                                    child: Text('In Progress'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Order has been sent to customer',
                                    child:
                                        Text('Order has been sent to customer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Cancelled',
                                    child: Text('Cancelled'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: updateStatus,
                                child: const Text('Update Status'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}
