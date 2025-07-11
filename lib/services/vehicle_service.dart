import 'dart:convert';
import 'package:greendrive/model/vehicle.dart';
import 'package:greendrive/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VehicleService {

  Future<List<Vehicle>> fetchCatalog() async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vehicleCatalog'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      List data = json.decode(resp.body);
      return data.map((e) => Vehicle.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load vehicle catalog');
    }
  }

  Future<void> registerVehicle(int userId, int vehiculoId) async {
    final token = await _getToken();
    final resp = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/user/$userId/assign-vehicle/$vehiculoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to register vehicle');
    }
  }

  Future<Vehicle?> fetchCurrentVehicle(int userId) async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      if (data['vehiculoId'] != null) {
        final vehicleId = data['vehiculoId'];
        final catalog = await fetchCatalog();

        final matches = catalog.where((v) => v.id == vehicleId);
        if (matches.isNotEmpty) {
          return matches.first;
        } else {
          return null;
        }
      }
      return null;
    } else {
      throw Exception('Failed to load current vehicle');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
