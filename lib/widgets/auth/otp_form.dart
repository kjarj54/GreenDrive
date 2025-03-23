import 'package:flutter/material.dart';

class OTPForm extends StatelessWidget {
  final Function() onVerify;
  final bool isLoading;
  final TextEditingController otpController;

  const OTPForm({
    Key? key,
    required this.onVerify,
    this.isLoading = false,
    required this.otpController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Código OTP',
            hintText: 'Ingresa el código de 6 dígitos',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: isLoading ? null : onVerify,
          child: const Text(
            'Verificar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
