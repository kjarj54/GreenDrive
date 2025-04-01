import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:greendrive/widgets/shared/gradient_background.dart';
import '../widgets/auth/signup_header.dart';
import '../widgets/auth/signup_form.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleSignup(
    String nombre,
    String email,
    String password,
  ) async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.register(nombre, email, password);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registration successful! Please login.'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Navigator.pop(context); // Return to login screen
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SignupHeader(),
                  SignupForm(
                    onSignup: _handleSignup,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: Colors.green.shade700,
          size: 22,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      toolbarHeight: 64,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
    );
  }
}
