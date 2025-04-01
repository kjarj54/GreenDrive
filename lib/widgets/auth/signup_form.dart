import 'package:flutter/material.dart';
import 'package:greendrive/widgets/shared/custom_textfield.dart';

class SignupForm extends StatefulWidget {
  final Function(String nombre, String email, String password) onSignup;
  final bool isLoading;

  const SignupForm({Key? key, required this.onSignup, this.isLoading = false})
    : super(key: key);

  @override
  State<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends State<SignupForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
    return CustomTextField(
      controller: _nombreController,
      labelText: 'Nombre',
      hintText: 'Introduce tu nombre completo',
      prefixIcon: Icons.person_outline,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Por favor ingresa tu nombre';
        }
        return null;
      },
    );
  }

   Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      labelText: 'Email',
      hintText: 'Introduce tu email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return 'Por favor ingresa tu email';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
          return 'Por favor ingresa un email válido';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        CustomTextField(
          controller: _passwordController,
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
            if (value!.length < 6) {
              return 'La contraseña debe tener al menos 6 caracteres';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _confirmPasswordController,
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
            if (value != _passwordController.text) {
              return 'Las contraseñas no coinciden';
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
      onPressed: widget.isLoading
          ? null
          : () {
              if (_formKey.currentState!.validate()) {
                widget.onSignup(
                  _nombreController.text,
                  _emailController.text,
                  _passwordController.text,
                );
              }
            },
      child: widget.isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text(
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
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
      textAlign: TextAlign.center,
    );
  }
}
