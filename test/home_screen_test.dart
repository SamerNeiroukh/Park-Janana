// test/home_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/screens/home/home_screen.dart';
import 'package:park_janana/constants/app_theme.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets('HomeScreen in testMode renders minimal UI', (tester) async {
    // No auth needed; testMode returns a tiny scaffold.
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(role: 'worker', testMode: true),
      ),
    );

    expect(find.text('Home (test)'), findsOneWidget);
    // Make sure no spinner / heavy widgets
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('HomeScreen shows "no user" fallback when currentUser == null',
      (tester) async {
    final mockAuth = _MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          role: 'worker',
          firebaseAuth: mockAuth,
          testMode: false, // we want to cover the real fallback branch
        ),
      ),
    );

    // Hebrew message: "לא נמצא משתמש מחובר"
    expect(find.textContaining('לא נמצא משתמש מחובר'), findsOneWidget);
  });
}
