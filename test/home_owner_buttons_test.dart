import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Owner role renders business reports action', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('own-1');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          role: 'owner',
          firebaseAuth: mockAuth,
          skipAsync: true,
          skipHeavyChildrenInTests: true,
        ),
      ),
    );

    final state = tester.state(find.byType(HomeScreen));
    (state as dynamic).debugSetDataForTest(
      userData: {'fullName': 'Owner', 'profile_picture': '', 'role': 'owner'},
      workStats: {'hoursWorked': 4.0, 'daysWorked': 2.0},
      weatherData: {'description': 'ok', 'temperature': '19'},
    );
    await tester.pump();

    expect(find.text('דו"חות עסקיים'), findsOneWidget);
  });
}
