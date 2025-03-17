import 'package:flutter/material.dart';
import 'package:greendrive/widgets/shared/custom_textfield.dart';

class SignupForm extends StatefulWidget {
  final VoidCallback onSignup;

  const SignupForm({
    Key? key,
    required this.onSignup,
  }) : super(key: key);

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildNameFields(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPhoneField(),
          const SizedBox(height: 16),
          _buildPasswordFields(),
          const SizedBox(height: 24),
          _buildSignupButton(),
          const SizedBox(height: 24),
          _buildLoginPrompt(),
          const SizedBox(height: 16),
          _buildTermsText(),
        ],
      ),
    );
  }

  Widget _buildNameFields() {
    return Row(
      children: [
        Expanded(
          child: CustomTextField(
            labelText: 'Nombre',
            hintText: 'Introduce tu nombre',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor ingresa tu nombre';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomTextField(
            labelText: 'Apellido',
            hintText: 'Introduce tu apellido',
            prefixIcon: Icons.person_outline,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Por favor ingresa tu apellido';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      labelText: 'Email',
      hintText: 'Introduce tu email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Por favor ingresa tu email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return CustomTextField(
      labelText: 'Phone Number',
      hintText: 'Enter your phone number',
      prefixIcon: Icons.phone_outlined,
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Por favor ingresa tu número de teléfono';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        CustomTextField(
          labelText: 'Password',
          hintText: 'Create your password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isPasswordVisible,
          onVisibilityToggle: () {
            setState(() => _isPasswordVisible = !_isPasswordVisible);
          },
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor ingresa tu contraseña';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          labelText: 'Confirm Password',
          hintText: 'Confirm your password',
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          isPasswordVisible: _isConfirmPasswordVisible,
          onVisibilityToggle: () {
            setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible);
          },
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Por favor confirma tu contraseña';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          widget.onSignup();
        }
      },
      child: const Text(
        'Sign Up',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Sign In',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By signing up, you agree to our Terms & Conditions\nand Privacy Policy',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }
}