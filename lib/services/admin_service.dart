import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:greendrive/model/station.dart';
import 'package:greendrive/utils/api_config.dart';
import 'package:greendrive/services/auth_services.dart';

class AdminService {
  final AuthService _authService;

  AdminService(this._authService);

  /// Crear una nueva estación de carga
  Future<ChargingStation> createStation({
    required String name,
    required double latitude,
    required double longitude,
    required String address,
    required String chargerType,
    required int power,
    required double rate,
    required bool availability,
    required String schedule,
  }) async {
    final token = await _authService.getToken();
    
    final stationData = {
      'nombre': name,
      'latitud': latitude,
      'longitud': longitude,
      'direccion': address,
      'tipoCargador': chargerType,
      'potencia': power,
      'tarifa': rate,
      'disponibilidad': availability,
      'horario': schedule,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chargingStations'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(stationData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ChargingStation.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error creating station');
    }
  }

  /// Enviar notificación masiva a todos los usuarios
  Future<void> sendBroadcastNotification({
    required String message,
    String type = 'GENERAL',
  }) async {
    final token = await _authService.getToken();
    
    final notificationData = {
      'mensaje': message,
      'tipo': type,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/broadcast'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(notificationData),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error sending notification');
    }
  }

  /// Actualizar una estación existente
  Future<ChargingStation> updateStation({
    required int stationId,
    required String name,
    required double latitude,
    required double longitude,
    required String address,
    required String chargerType,
    required int power,
    required double rate,
    required bool availability,
    required String schedule,
  }) async {
    final token = await _authService.getToken();
    
    final stationData = {
      'nombre': name,
      'latitud': latitude,
      'longitud': longitude,
      'direccion': address,
      'tipoCargador': chargerType,
      'potencia': power,
      'tarifa': rate,
      'disponibilidad': availability,
      'horario': schedule,
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/chargingStations/$stationId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(stationData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ChargingStation.fromJson(data);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error updating station');
    }
  }

  /// Eliminar una estación
  Future<void> deleteStation(int stationId) async {
    final token = await _authService.getToken();

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/chargingStations/$stationId'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Error deleting station');
    }
  }
}
