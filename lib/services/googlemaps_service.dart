import 'package:flutter_google_maps_webservices/directions.dart'
    show
        GoogleMapsDirections,
        TravelMode,
        Location,
        Waypoint;
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyAMzZmfXiznm3HQ7T6FwYe1Z5i0HJj-5Vc'; // Replace with your API key
  final places = GoogleMapsPlaces(apiKey: _apiKey);
  final directions = GoogleMapsDirections(apiKey: _apiKey);

  /// origin, destination y opcionalmente waypoints
  Future<List<LatLng>> getDirections(
    LatLng origin,
    LatLng destination, {
    List<LatLng> waypoints = const [],
  }) async {
    // Convertir LatLng -> Waypoint
    final wp =
        waypoints
            .map((w) => Waypoint(value: '${w.latitude},${w.longitude}'))
            .toList();

    final resp = await directions.directionsWithLocation(
      Location(lat: origin.latitude, lng: origin.longitude),
      Location(lat: destination.latitude, lng: destination.longitude),
      travelMode: TravelMode.driving,
      waypoints: wp, // ¡aquí van las paradas!
    );

    if (resp.status != 'OK' || resp.routes.isEmpty) {
      throw Exception('Failed to get directions');
    }

    final encoded = resp.routes.first.overviewPolyline.points;
    // Decodifica en una lista de LatLng
    return decodePolyline(encoded).map((p) => LatLng(p[0], p[1])).toList();
  }

  List<List<double>> decodePolyline(String encoded) {
    final poly = <List<double>>[];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));

      poly.add([lat / 1E5, lng / 1E5]);
    }
    return poly;
  }
}
