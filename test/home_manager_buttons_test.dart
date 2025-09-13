import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Manager role renders manager-specific actions', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('mgr-1');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          role: 'manager',
          firebaseAuth: mockAuth,
          skipAsync: true,
          skipHeavyChildrenInTests: true,
        ),
      ),
    );

    final state = tester.state(find.byType(HomeScreen));
    (state as dynamic).debugSetDataForTest(
      userData: {'fullName': 'Boss', 'profile_picture': '', 'role': 'manager'},
      workStats: {'hoursWorked': 3.0, 'daysWorked': 1.0},
      weatherData: {'description': 'ok', 'temperature': '20'},
    );
    await tester.pump();

    expect(find.text('ניהול משמרות'), findsOneWidget);
    expect(find.text('ניהול משימות'), findsOneWidget);
    expect(find.text('ניהול עובדים'), findsOneWidget);
  });
}
