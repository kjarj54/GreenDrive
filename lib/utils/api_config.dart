import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://192.168.0.14:8080';
    }
    return 'http://localhost:8080';
  }
}
