import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  int? _userId;
  String? _name;
  String? _email;

  int? get userId => _userId;
  String? get name => _name;
  String? get email => _email;

  void setUser({
    required int id,
    required String name,
    required String email,
  }) async {
    _userId = id;
    _name = name;
    _email = email;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      _userId = prefs.getInt('userId');
      _name = prefs.getString('name');
      _email = prefs.getString('email');
      notifyListeners();
    }
  }

  void clearUser() async {
    _userId = null;
    _name = null;
    _email = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('name');
    await prefs.remove('email');
  }

  bool get isLoggedIn => _userId != null;
}
