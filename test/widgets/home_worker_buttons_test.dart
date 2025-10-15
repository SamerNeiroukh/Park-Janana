import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Worker role renders worker-specific actions', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('u-2');
    when(() => mockAuth.currentUser).thenReturn(mockUser);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          role: 'worker',
          firebaseAuth: mockAuth,
          skipAsync: true,
          skipHeavyChildrenInTests: true,
        ),
      ),
    );

    final state = tester.state(find.byType(HomeScreen));
    (state as dynamic).debugSetDataForTest(
      userData: {'fullName': 'QA', 'profile_picture': '', 'role': 'worker'},
      workStats: {'hoursWorked': 2.0, 'daysWorked': 1.0},
      weatherData: {'description': 'ok', 'temperature': '20'},
    );
    await tester.pump();

    // Base actions:
    expect(find.text('פרופיל'), findsOneWidget);
    expect(find.textContaining('דו"חות'), findsOneWidget);

    // Worker-only actions:
    expect(find.text('המשימות שלי'), findsOneWidget);
    expect(find.text('המשמרות שלי'), findsOneWidget);
  });
}
