import 'dart:convert';
import 'dart:math';
import 'package:greendrive/model/station.dart';
import 'package:http/http.dart' as http;
import 'auth_services.dart';

class ChargingStationService {
  final AuthService _authService;

  ChargingStationService(this._authService);

  Future<List<ChargingStation>> getNearbyStations(double lat, double lng, double radius) async {
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('No authentication token found');
        throw Exception('No authentication token');
      }

      print('Fetching stations at ($lat, $lng) with radius ${radius}km');
      final response = await http.get(
        Uri.parse('${AuthService.baseUrl}/chargingStations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Station API response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Retrieved ${data.length} stations from API');
        final stations = data.map((json) => ChargingStation.fromJson(json)).toList();
        
        // Filtrar estaciones por radio (en kilómetros)
        final nearbyStations = stations.where((station) {
          final distance = _calculateDistance(
            lat, lng, station.latitude, station.longitude);
          return distance <= radius;
        }).toList();
        
        print('Found ${nearbyStations.length} stations within ${radius}km radius');
        return nearbyStations;
      } else {
        print('Error response body: ${response.body}');
        throw Exception('Failed to load stations');
      }
    } catch (e) {
      print('Error getting nearby stations: $e');
      rethrow;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Radio de la Tierra en km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      sin(dLat/2) * sin(dLat/2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
      sin(dLon/2) * sin(dLon/2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}