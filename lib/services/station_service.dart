import 'dart:convert';
import 'dart:math';
import 'package:greendrive/model/station.dart';
import 'package:http/http.dart' as http;
import 'auth_services.dart';
import 'package:greendrive/utils/api_config.dart';

class ChargingStationService {
  final AuthService _authService;

  ChargingStationService(this._authService);

  Future<List<ChargingStation>> getNearbyStations(
    double lat,
    double lng,
    double radius,
  ) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/chargingStations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load stations');
    }

    final List<dynamic> data = json.decode(response.body);
    final stations = data.map((j) => ChargingStation.fromJson(j)).toList();

    // Filtrar por radio en km
    return stations.where((s) {
      final d = _calculateDistance(lat, lng, s.latitude, s.longitude);
      return d <= radius;
    }).toList();
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double deg) => deg * pi / 180;

  Future<Map<String, dynamic>> getStationStats(
    double lat,
    double lng,
    double radius,
  ) async {
    final stations = await getNearbyStations(lat, lng, radius);

    return {
      'totalStations': stations.length,
      'availableStations': stations.where((s) => s.availability).length,
      'avgRating':
          stations.isEmpty
              ? 0.0
              : stations.map((s) => s.rating).reduce((a, b) => a + b) /
                  stations.length,
      'totalCharges': stations
          .map((s) => s.totalCharges)
          .reduce((a, b) => a + b),
      'topRated':
          stations.isEmpty
              ? null
              : stations.reduce((a, b) => a.rating > b.rating ? a : b),
      'mostUsed':
          stations.isEmpty
              ? null
              : stations.reduce(
                (a, b) => a.totalCharges > b.totalCharges ? a : b,
              ),
    };
  }

  Future<List<ChargingStation>> getTopRatedStations(
    double lat,
    double lng,
    double radius,
  ) async {
    final stations = await getNearbyStations(lat, lng, radius);
    return stations.where((s) => s.rating >= 4.0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }
}
