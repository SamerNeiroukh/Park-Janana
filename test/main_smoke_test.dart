import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart'; // only for the User? type

// ⬇️ replace with your actual pubspec `name:`
import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/welcome_screen.dart';

void main() {
  testWidgets('Splash → Welcome when no user', (tester) async {
    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: Stream<User?>.value(null),
      ),
    );

    // initial: Splash
    expect(find.byType(SplashScreen), findsOneWidget);

    // advance past splash + let the frame rebuild
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    // no user ⇒ Welcome
    expect(find.byType(WelcomeScreen), findsOneWidget);

    // give any pending timers/microtasks a chance to flush before test exits
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
  });
}
