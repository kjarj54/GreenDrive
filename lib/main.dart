import 'package:flutter/material.dart';
import 'package:greendrive/screens/login_screen.dart';
import 'package:greendrive/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:greendrive/providers/user_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MainApp(),
    ),
  );
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
