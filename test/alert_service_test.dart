import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/utils/alert_service.dart';
import 'package:park_janana/constants/app_colors.dart';

void main() {
  group('AlertService', () {
    testWidgets('displays success alert with correct styling', (WidgetTester tester) async {
      // Build a simple widget that uses AlertService
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlertService.success(context, 'Test message'),
                child: const Text('Show Alert'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show alert
      await tester.tap(find.text('Show Alert'));
      await tester.pump();

      // Verify that the snackbar appears with correct content
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Test message'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('displays error alert with correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlertService.error(context, 'Error message'),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show alert
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Verify error alert styling
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays confirmation dialog with RTL support', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AlertService.confirm(
                  context,
                  title: 'Test Title',
                  message: 'Test Message',
                ),
                child: const Text('Show Confirm'),
              ),
            ),
          ),
        ),
      );

      // Tap the button to show confirmation dialog
      await tester.tap(find.text('Show Confirm'));
      await tester.pumpAndSettle();

      // Verify dialog appears with correct content
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Message'), findsOneWidget);
      expect(find.text('אישור'), findsOneWidget); // Confirm button
      expect(find.text('ביטול'), findsOneWidget); // Cancel button

      // Verify RTL support
      expect(find.byType(Directionality), findsOneWidget);
    });
  });
}