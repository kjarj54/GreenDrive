import 'package:flutter/material.dart';
import 'package:greendrive/screens/login_screen.dart';
import 'package:greendrive/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      checkerboardRasterCacheImages: false,
      debugShowMaterialGrid: false,
      title: 'GreenDrive',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const LoginScreen(),
    );
  }
}
