import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/welcome_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets('/profile shows fallback when no user', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: Stream<User?>.value(null),
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true,
      ),
    );

    // past splash
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    expect(find.byType(WelcomeScreen), findsOneWidget);

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/profile');
    await tester.pumpAndSettle();

    expect(find.textContaining('No user is logged in'), findsOneWidget);
  });
}
