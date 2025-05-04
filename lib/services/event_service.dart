import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event.dart';

class EventService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
  
  // Get all events
  Future<List<Event>> getEvents() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((item) => Event.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }
  
  // Create an event
  Future<Event> createEvent(Event event) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(event.toJson()),
    );
    
    if (response.statusCode == 201) {
      return Event.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create event');
    }
  }
  
  // Register for an event
  Future<void> registerForEvent(int eventId, int userId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/userEvents?eventoId=$eventId&usuarioId=$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to register for event');
    }
  }
  
  // Get event participants
  Future<List<Map<String, dynamic>>> getEventParticipants(int eventId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/userEvents/event/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load participants');
    }
  }
  
  // Delete an event
  Future<void> deleteEvent(int eventId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$eventId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    if (response.statusCode != 204) {
      throw Exception('Failed to delete event');
    }
  }
  
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
}