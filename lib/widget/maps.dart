import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:kongkon_app_driver/shared/theme.dart';
import 'package:latlong2/latlong.dart';

class MapContainer extends StatelessWidget {
  final LatLng? merchantLocation;
  final LatLng? customerLocation;
  final Map<String, dynamic>? orderDetails;
  final Map<String, dynamic>? userDetails;
  final LatLng? currentLocation;
  const MapContainer({
    Key? key,
    this.merchantLocation,
    this.customerLocation,
    this.orderDetails,
    this.userDetails,
    this.currentLocation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final driverPosition = currentLocation;
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
      ),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: merchantLocation!, // Fallback to default location
          minZoom: 14.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          PolylineLayer(
            polylines: _buildPolylines(driverPosition),
          ),
          MarkerLayer(
            markers: _buildMarkers(driverPosition),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(LatLng? driverPosition) {
    final markers = <Marker>[];

    // Merchant marker
    if (merchantLocation != null) {
      markers.add(
        Marker(
          point: merchantLocation!,
          width: 30.0,
          height: 30.0,
          child: Icon(Icons.store, color: kRedColor, size: 20),
        ),
      );
    }

    // Customer marker
    if (customerLocation != null) {
      markers.add(
        Marker(
          point: customerLocation!,
          width: 30.0,
          height: 30.0,
          child:
              Icon(Icons.person_pin_circle_rounded, color: kRedColor, size: 20),
        ),
      );
    }

    // Driver marker
    if (driverPosition != null) {
      markers.add(
        Marker(
          point: driverPosition,
          width: 30.0,
          height: 30.0,
          child: Icon(Icons.motorcycle, color: kPrimaryColor, size: 20),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines(LatLng? driverPosition) {
    final polylines = <Polyline>[];

    // Polyline from driver to merchant
    if (driverPosition != null && merchantLocation != null) {
      polylines.add(
        Polyline(
          points: [
            driverPosition,
            merchantLocation!,
          ],
          color: kPolylineColor,
          strokeWidth: 4.0,
        ),
      );
    }

    // Polyline from merchant to customer
    if (merchantLocation != null && customerLocation != null) {
      polylines.add(
        Polyline(
          points: [
            merchantLocation!,
            customerLocation!,
          ],
          color: kPolylineColor,
          strokeWidth: 4.0,
        ),
      );
    }

    return polylines;
  }
}
