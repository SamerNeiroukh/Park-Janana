// test/main_flow_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/welcome_screen.dart';
import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Splash → Home when user is signed in', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();

    when(() => mockUser.uid).thenReturn('u-123');
    when(() => mockUser.email).thenReturn('qa@example.com');
    when(() => mockUser.displayName).thenReturn('QA');
    when(() => mockUser.isAnonymous).thenReturn(false);
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: Stream<User?>.value(mockUser),
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true, // <- skip IO/animations
      ),
    );

    // starts on splash
    expect(find.byType(SplashScreen), findsOneWidget);

    // past splash
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    // lands on Home
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('Splash → Welcome when no user', (tester) async {
    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: Stream<User?>.value(null),
        enableHomeTestMode: true,
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('After splash, auth waiting shows CircularProgressIndicator',
      (tester) async {
    final mockAuth = _MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);

    // Never emits -> StreamBuilder stays in ConnectionState.waiting
    final controller = StreamController<User?>();

    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: controller.stream,
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true,
      ),
    );

    // Initially splash (no spinner yet)
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Past splash
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    // In waiting state -> spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Don’t pumpAndSettle on an infinite spinner. Just tick once and close.
    await tester.pump(const Duration(milliseconds: 16));
    await controller.close();
  });
}
