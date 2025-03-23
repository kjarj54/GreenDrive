import 'dart:convert';
import 'package:greendrive/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8080';
  static const String tokenKey = 'auth_token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': email, 'contrasena': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'usuarioId': data['usuarioId'],
          'email': email,
        };
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else {
        throw Exception('Error en login: ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error en login: $e');
      rethrow;
    }
  }

  Future<User> verifyOTP(int usuarioId, String codigo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usuarioId': usuarioId, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);

        if (user.token != null) {
          await _saveToken(user.token!);
        } else {
          throw Exception('Token no encontrado en la respuesta');
        }

        return user;
      } else {
        throw Exception('OTP inválido o expirado');
      }
    } catch (e) {
      print('Error al verificar OTP: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _removeToken();
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }
}
