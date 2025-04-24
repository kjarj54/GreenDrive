import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  int? _userId;
  String? _name;
  String? _email;

  int? get userId => _userId;
  String? get name => _name;
  String? get email => _email;

  void setUser({required int id, required String name, required String email}) {
    _userId = id;
    _name = name;
    _email = email;
    notifyListeners();
  }

  void clearUser() {
    _userId = null;
    _name = null;
    _email = null;
    notifyListeners();
  }
}
