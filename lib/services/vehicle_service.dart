import 'dart:convert';
import 'dart:io';
import 'package:greendrive/model/vehicle.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VehicleService {
  static String get baseUrl {
    // You can add more platform-specific logic here
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  Future<List<Vehicle>> fetchCatalog() async {
    final token = await _getToken();
    final resp = await http.get(
      Uri.parse('$baseUrl/vehicleCatalog'),
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
      Uri.parse('$baseUrl/user/$userId/assign-vehicle/$vehiculoId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed to register vehicle');
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}
