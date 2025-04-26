import 'package:flutter_google_maps_webservices/places.dart';
import 'package:flutter_google_maps_webservices/directions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyAMzZmfXiznm3HQ7T6FwYe1Z5i0HJj-5Vc'; // Replace with your API key
  final places = GoogleMapsPlaces(apiKey: _apiKey);
  final directions = GoogleMapsDirections(apiKey: _apiKey);

  Future<List<PlacesSearchResult>> getNearbyChargingStations(LatLng location, double radius) async {
    final response = await places.searchNearbyWithRadius(
      Location(lat: location.latitude, lng: location.longitude),
      radius,
      type: 'charging_station',
      keyword: 'ev charging station',
    );

    if (response.status == "OK") {
      return response.results;
    } else {
      throw Exception('Failed to load charging stations');
    }
  }

  Future<List<LatLng>> getDirections(LatLng origin, LatLng destination) async {
    final response = await directions.directionsWithLocation(
      Location(lat: origin.latitude, lng: origin.longitude),
      Location(lat: destination.latitude, lng: destination.longitude),
      travelMode: TravelMode.driving,
    );

    if (response.status == "OK") {
      final points = response.routes.first.overviewPolyline.points;
      return decodePolyline(points)
          .map((point) => LatLng(point[0], point[1]))
          .toList();
    } else {
      throw Exception('Failed to get directions');
    }
  }

  List<List<double>> decodePolyline(String encoded) {
    List<List<double>> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add([lat / 1E5, lng / 1E5]);
    }
    return poly;
  }
}