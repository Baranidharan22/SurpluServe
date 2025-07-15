import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapScreen extends StatefulWidget {
  final double donorLat;
  final double donorLng;
  final double receiverLat;
  final double receiverLng;

  const MapScreen({
    super.key,
    required this.donorLat,
    required this.donorLng,
    required this.receiverLat,
    required this.receiverLng,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  String? _distanceText;
  String? _durationText;

  @override
  void initState() {
    super.initState();
    _setMarkers();
    _getRoute();
  }

  void _setMarkers() {
    _markers.add(Marker(
      markerId: const MarkerId("donor"),
      position: LatLng(widget.donorLat, widget.donorLng),
      infoWindow: const InfoWindow(title: "Donor"),
    ));

    _markers.add(Marker(
      markerId: const MarkerId("receiver"),
      position: LatLng(widget.receiverLat, widget.receiverLng),
      infoWindow: const InfoWindow(title: "You"),
    ));
  }

  Future<void> _getRoute() async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY']; // Replace with your actual API Key
    final origin = '${widget.receiverLat},${widget.receiverLng}';
    final destination = '${widget.donorLat},${widget.donorLng}';

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0];
        final points = _decodePolyline(route['overview_polyline']['points']);
        final leg = route['legs'][0];

        setState(() {
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ));
          _distanceText = leg['distance']['text'];
          _durationText = leg['duration']['text'];
        });
      } else {
        debugPrint("No routes found: ${data['status']}");
      }
    } catch (e) {
      debugPrint("Error fetching directions: $e");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialCenter = LatLng(widget.receiverLat, widget.receiverLng);

    return Scaffold(
      appBar: AppBar(title: const Text("Route to Donor")),
      body: Column(
        children: [
          Expanded(
            child: kIsWeb
                ? const Center(child: Text("Google Maps not supported on web via `google_maps_flutter`. Use another widget or platform."))
                : GoogleMap(
              initialCameraPosition: CameraPosition(target: initialCenter, zoom: 13),
              markers: _markers,
              polylines: _polylines,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),
          if (_distanceText != null && _durationText != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Distance: $_distanceText | Duration: $_durationText',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
