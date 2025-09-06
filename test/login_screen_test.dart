import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/screens/auth/login_screen.dart';

void main() {
  group('LoginScreen Tests', () {
    testWidgets('should have autofill hints for email and password fields', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Find AutofillGroup
      expect(find.byType(AutofillGroup), findsOneWidget);

      // Find TextFormFields with autofill hints
      final emailField = tester.widget<TextFormField>(
        find.byWidgetPredicate((widget) => 
          widget is TextFormField && 
          widget.autofillHints?.contains(AutofillHints.email) == true
        )
      );
      expect(emailField.autofillHints, contains(AutofillHints.email));

      final passwordField = tester.widget<TextFormField>(
        find.byWidgetPredicate((widget) => 
          widget is TextFormField && 
          widget.autofillHints?.contains(AutofillHints.password) == true
        )
      );
      expect(passwordField.autofillHints, contains(AutofillHints.password));
    });

    testWidgets('should have proper form validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Find the login button
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);

      // Tap login button without entering data
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation errors
      expect(find.text('אנא הכנס כתובת אימייל'), findsOneWidget);
      expect(find.text('אנא הכנס סיסמה'), findsOneWidget);
    });

    testWidgets('should have modern UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Check for modern UI elements
      expect(find.byType(Container), findsWidgets); // Card-like container
      expect(find.byIcon(Icons.person), findsOneWidget); // User icon
      expect(find.byIcon(Icons.email_outlined), findsOneWidget); // Email icon
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget); // Lock icon
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget); // Password visibility toggle
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen()));

      // Find password field and visibility toggle
      final visibilityButton = find.byIcon(Icons.visibility_outlined);
      expect(visibilityButton, findsOneWidget);

      // Tap to toggle visibility
      await tester.tap(visibilityButton);
      await tester.pump();

      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}