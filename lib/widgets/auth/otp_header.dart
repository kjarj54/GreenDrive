import 'package:flutter/material.dart';

class OTPHeader extends StatelessWidget {
  final String email;

  const OTPHeader({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'appLogo',
          child: Icon(
            Icons.lock_outline,
            size: 100,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Verifica tu identidad',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el código enviado a $email',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
