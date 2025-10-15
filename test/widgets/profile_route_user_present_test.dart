import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('/profile shows PersonalAreaScreen when user exists',
      (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('u-42');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream:
            Stream<User?>.value(null), // stay on Welcome after splash
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true,
      ),
    );

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pushNamed('/profile');
    await tester.pumpAndSettle();

    expect(find.byType(PersonalAreaScreen), findsOneWidget);
  });
}
