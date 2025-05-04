import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/rating.dart';

class RatingService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  
  // Obtener calificaciones de una estación
  Future<List<StationRating>> getRatingsByStation(int stationId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/ratings/station/$stationId'),
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
  Future<StationRating> addRating(int userId, int stationId, int rating, [String? comment]) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/ratings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'usuarioId': userId,
        'estacionId': stationId,
        'calificacion': rating,
        'comentario': comment,
        'fecha': DateTime.now().toIso8601String(),
      }),
    );
    
    if (response.statusCode == 201) {
      return StationRating.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add rating');
    }
  }
  
  // Eliminar una calificación
  Future<void> deleteRating(int ratingId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/ratings/$ratingId'),
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