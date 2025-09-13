import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import 'package:park_janana/main.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  testWidgets('After splash, auth waiting shows CircularProgressIndicator',
      (tester) async {
    final mockAuth = _MockFirebaseAuth();
    when(() => mockAuth.currentUser).thenReturn(null);

    // A stream that never emits keeps ConnectionState.waiting
    final controller = StreamController<User?>(); // never add/close

    await tester.pumpWidget(
      MyApp(
        overrideSplashDuration: const Duration(milliseconds: 1),
        overrideAuthStream: controller.stream,
        overrideHomeAuthInstance: mockAuth,
        enableHomeTestMode: true,
      ),
    );

    // Splash first
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Past splash
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();

    // StreamBuilder waiting state ⇒ spinner
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

// Don't wait for settle — spinner is infinite.
// Just tick one frame (optional) and tidy up.
    await tester.pump(const Duration(milliseconds: 16));
    await controller.close();
  });
}
