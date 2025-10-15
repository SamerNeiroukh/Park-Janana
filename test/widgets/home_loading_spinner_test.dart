import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Home shows spinner when user present but data not loaded',
      (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('u-1');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          role: 'worker',
          firebaseAuth: mockAuth,
          // don’t kick off async work; heavy children off
          skipAsync: true,
          skipHeavyChildrenInTests: true,
        ),
      ),
    );

    // initial state: _userData/_workStats are null => spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // now “pretend” the async work finished: fill state manually
    final state = tester.state(find.byType(HomeScreen));
    (state as dynamic).debugSetDataForTest(
      userData: {'fullName': 'QA', 'profile_picture': '', 'role': 'worker'},
      workStats: {'hoursWorked': 1.0, 'daysWorked': 1.0},
      weatherData: {'description': 'sunny', 'temperature': '25'},
    );
    await tester.pump();

    // grid appears (we skipped UserCard/Clock only)
    expect(find.text('פרופיל'), findsOneWidget);
    expect(find.textContaining('דו"חות'), findsOneWidget);
  });
}
