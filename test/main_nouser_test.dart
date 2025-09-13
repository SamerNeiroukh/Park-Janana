import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/welcome_screen.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets('Splash → Welcome when no user', (tester) async {
    final mockAuth = _MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);

    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: const Stream<User?>.empty(), // no user ever
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true, // safe: we won’t even hit Home
      ),
    );

    // Start on Splash
    expect(find.byType(SplashScreen), findsOneWidget);

    // After splash finishes, should land on Welcome
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
