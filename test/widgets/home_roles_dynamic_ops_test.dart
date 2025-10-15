import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/screens/home/home_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Dynamic ops from roles.json are rendered', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();
    when(() => mockUser.uid).thenReturn('u-roles');
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

    final roleData = {
      'worker': [
        {
          'title': 'פעולה מותאמת',
          'icon': 0xe14f
        }, // any Material icon codepoint
      ],
    };

    final state = tester.state(find.byType(HomeScreen));
    (state as dynamic).debugSetDataForTest(
      userData: {'fullName': 'QA', 'profile_picture': '', 'role': 'worker'},
      workStats: {'hoursWorked': 1.0, 'daysWorked': 1.0},
      weatherData: {'description': 'ok', 'temperature': '20'},
      roleData: roleData,
    );
    await tester.pump();

    expect(find.text('פעולה מותאמת'), findsOneWidget);
  });
}
