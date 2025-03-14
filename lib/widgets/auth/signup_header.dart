import 'package:flutter/material.dart';

class SignupHeader extends StatelessWidget {
  const SignupHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'appLogo',
          child: Icon(
            Icons.electric_car,
            size: 80,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 40),
        Text(
          'Create Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.green.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia con la revolucion eco-friendly ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}