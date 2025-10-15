// test/routes_and_misc_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/welcome_screen.dart';
import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets('Routes: /home and /login resolve correctly', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    // Keep app idle on Welcome after splash by emitting null
    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: Stream<User?>.value(null),
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true,
      ),
    );

    // Past splash -> Welcome
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // Push /home -> should render test-mode HomeScreen
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/home');
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    // Push /login -> WelcomeScreen
    nav.pushNamed('/login');
    await tester.pumpAndSettle();
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('MaterialApp builder enforces LTR Directionality',
      (tester) async {
    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: Stream<User?>.value(null),
        enableHomeTestMode: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    // Grab any widget context in the tree and verify LTR
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Directionality.of(ctx), TextDirection.ltr);
  });
}
