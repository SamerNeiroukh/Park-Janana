import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/home/home_screen.dart';

// Simple mocks with mocktail
class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockUser extends Mock implements User {}

void main() {
  testWidgets('Splash → Home when user is signed in', (tester) async {
    // Arrange: mock a signed-in user + auth
    final mockAuth = _MockFirebaseAuth();
    final mockUser = _MockUser();

    when(() => mockUser.uid).thenReturn('u-123');
    when(() => mockUser.email).thenReturn('qa@example.com');
    when(() => mockUser.displayName).thenReturn('QA');
    when(() => mockUser.isAnonymous).thenReturn(false);

    when(() => mockAuth.currentUser).thenReturn(mockUser);

    // Act: pump app with overrides (no real Firebase init needed)
    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        // The StreamBuilder in MyApp will see "a user is present"
        overrideAuthStream: Stream<User?>.value(mockUser),
        // HomeScreen will read currentUser from our mock auth (not platform)
        overrideHomeAuthInstance: mockAuth,
        // Skip Firestore/Clock/Weather in tests
        enableHomeTestMode: true,
      ),
    );

    // Assert: splash shown, then HomeScreen once splash elapses
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    expect(find.byType(HomeScreen), findsOneWidget);

// Flush any pending microtasks/zero-delay timers just in case.
    await tester.pumpAndSettle();
  });
}
