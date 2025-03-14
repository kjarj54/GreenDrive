import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'appLogo',
          child: Icon(
            Icons.electric_car,
            size: 100,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Welcome to GreenDrive',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu eco-friendly viaje comienza aquí',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}