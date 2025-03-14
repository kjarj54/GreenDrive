import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greendrive/main.dart';
import 'package:greendrive/screens/login_screen.dart';

void main() {
  group('GreenDrive App Tests', () {
    testWidgets('Login screen shows correctly', (WidgetTester tester) async {
      // Build our app and trigger a frame
      await tester.pumpWidget(const MainApp());

      // Verify that the login screen is shown
      expect(find.byType(LoginScreen), findsOneWidget);
      
      // Verify that email and password fields are present
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      
      // Verify that login button exists
      expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
      
      // Verify that signup prompt exists
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(const MainApp());

      // Try to login without entering credentials
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();

      // Verify validation messages are shown
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });
  });
}