import 'dart:convert';
import 'package:greendrive/model/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:greendrive/utils/api_config.dart';

class AuthService {
  static const String tokenKey = 'auth_token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'correo': email, 'contrasena': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'usuarioId': data['usuarioId'], 'email': email};
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
        Uri.parse('${ApiConfig.baseUrl}/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usuarioId': usuarioId, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);

        if (user.token != null) {
          await _saveToken(user.token!);
          await _saveUserData(user);
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

  Future<User> register(String nombre, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'correo': email,
          'contrasena': password,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return User.fromJson(data);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error during registration');
      }
    } catch (e) {
      print('Error in registration: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('email');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', user.id);
    await prefs.setString('name', user.name);
    await prefs.setString('email', user.email);
  }
}
