import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapWidget extends StatelessWidget {
  final double latitude;
  final double longitude;

  const GoogleMapWidget({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: 14.0,
      ),
      markers: {
        Marker(
          markerId: MarkerId('orderLocation'),
          position: LatLng(latitude, longitude),
        ),
      },
    );
  }
}
