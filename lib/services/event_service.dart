import 'dart:convert';
import 'package:greendrive/utils/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../model/event.dart';

class EventService {
  Future<List<Event>> getEvents() async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/events'),
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

  Future<Event> createEvent(Event event) async {
    final token = await _getToken();
    print(json.encode(event.toJson()));
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/events'),
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

  Future<void> updateGroupStatus(int eventId, String newStatus) async {
    final token = await _getToken();
    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/events/$eventId/status?newStatus=$newStatus',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update group status');
    }
  }

  Future<void> updateEvent(Event event) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/events/${event.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(event.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update event');
    }
  }

  Future<void> registerForEvent(int eventId, int userId) async {
    final token = await _getToken();
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/userEvents?eventoId=$eventId&usuarioId=$userId',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to register for event');
    }
  }

  Future<void> unregisterFromEvent(int eventId, int userId) async {
    final token = await _getToken();

    final participants = await getEventParticipants(eventId);
    final userEntry = participants.firstWhere(
      (p) => p['usuarioId'] == userId,
      orElse: () => {},
    );

    if (userEntry.isEmpty || userEntry['id'] == null) {
      throw Exception('User is not registered in this event.');
    }

    final id = userEntry['id'];
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/userEvents/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to unregister from event');
    }
  }

  Future<List<Map<String, dynamic>>> getEventParticipants(int eventId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/userEvents/event/$eventId'),
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

  Future<void> deleteEvent(int eventId) async {
    final token = await _getToken();
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/events/$eventId'),
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
