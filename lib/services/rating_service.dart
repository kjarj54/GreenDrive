import 'dart:convert';
import 'package:greendrive/utils/api_config.dart';
import 'package:http/http.dart' as http;
import '../model/rating.dart';
import 'auth_services.dart';

class RatingService {
  final AuthService _authService;

  RatingService(this._authService);

  // Obtener calificaciones de una estación
  Future<List<StationRating>> getRatingsByStation(int stationId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/calificaciones-estaciones/estacion/$stationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => StationRating.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load ratings');
    }
  }
  // Enviar una nueva calificación
  Future<StationRating> addRating(
    int userId,
    int stationId,
    int rating, [
    String? comment,
  ]) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token');
    }    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/calificaciones-estaciones'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'usuarioId': userId,
        'estacionId': stationId,
        'calificacion': rating,
        'comentario': comment,
      }),
    );

    if (response.statusCode == 201) {
      return StationRating.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add rating');
    }
  }  // Eliminar una calificación
  Future<void> deleteRating(int ratingId) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('No authentication token');
    }

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/api/calificaciones-estaciones/$ratingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete rating');
    }
  }
}
