// Widget tests for Park Janana app.
//
// Tests the basic functionality of the app including the splash screen
// and initial app state.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';

void main() {
  testWidgets('App starts with splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the splash screen is displayed initially.
    expect(find.byType(SplashScreen), findsOneWidget);
    
    // Verify that the splash screen has expected elements.
    expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
  });

  testWidgets('Splash screen displays correctly', (WidgetTester tester) async {
    // Test the splash screen widget directly.
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Verify that the splash screen renders without errors.
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
