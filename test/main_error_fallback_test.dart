import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/welcome_screen.dart';

void main() {
  testWidgets('Auth stream error → Welcome', (tester) async {
    final controller = StreamController<User?>();
    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: controller.stream,
        enableHomeTestMode: true, // keeps Home lightweight if it’s reached
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2)); // past splash
    // emit an error (no data)
    controller.addError('boom');
    await tester.pump();

    // because hasData == false, we land on Welcome
    expect(find.byType(WelcomeScreen), findsOneWidget);
    await controller.close();
  });
}
