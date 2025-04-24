import 'package:flutter/material.dart';
import 'package:greendrive/providers/user_provider.dart';
import 'package:greendrive/screens/home_screen.dart';
import 'package:greendrive/services/auth_services.dart';
import 'package:greendrive/widgets/auth/otp_form.dart';
import 'package:greendrive/widgets/auth/otp_header.dart';
import 'package:greendrive/widgets/shared/gradient_background.dart';
import 'package:provider/provider.dart';

class OTPVerificationScreen extends StatefulWidget {
  final int usuarioId;
  final String email;

  const OTPVerificationScreen({
    Key? key,
    required this.usuarioId,
    required this.email,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final _authService = AuthService();
  final _otpController = TextEditingController();

  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    setState(() => _isLoading = true);

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _buildLoadingDialog(),
      );

      _loadingController.forward();

      final user = await _authService.verifyOTP(
        widget.usuarioId,
        _otpController.text.trim(),
      );

      Navigator.of(context).pop();

      if (user.token != null && user.token!.isNotEmpty && user.id > 0) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setUser(id: user.id, name: user.name, email: user.email);

        _showSuccessMessage();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        throw Exception(
          "Verification succeeded but essential user data is missing.",
        );
      }
    } catch (e) {
      Navigator.of(context).pop();

      final isOtpError = e.toString().contains("Invalid or expired OTP");
      final errorMessage =
          isOtpError
              ? "The OTP code is invalid or has expired. Please try again."
              : "An unexpected error occurred during verification. Please check the code and try again.";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
      _loadingController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OTPHeader(email: widget.email),
                  OTPForm(
                    onVerify: _handleVerify,
                    isLoading: _isLoading,
                    otpController: _otpController,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingDialog() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
            ),
            const SizedBox(height: 16),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Verificando OTP...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              '¡Verificado correctamente! 🌱',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
        animation: CurvedAnimation(
          parent: const AlwaysStoppedAnimation(1),
          curve: Curves.easeOut,
        ),
      ),
    );
  }
}
