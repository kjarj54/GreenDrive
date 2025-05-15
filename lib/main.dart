import 'package:flutter/material.dart';
import 'package:greendrive/screens/home_screen.dart';
import 'package:greendrive/screens/login_screen.dart';
import 'package:greendrive/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:greendrive/providers/user_provider.dart';
import 'package:greendrive/services/notification_service.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => UserProvider())],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenDrive',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home:
          !_initialized
              ? const Scaffold(body: Center(child: CircularProgressIndicator()))
              : userProvider.isLoggedIn
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}
