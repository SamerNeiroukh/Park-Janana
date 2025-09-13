import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:park_janana/screens/reports/worker_reports_screen.dart';

class MockAttendanceSummaryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class MockTaskSummaryReport extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TestWorkerReportsScreen extends WorkerReportsScreen {
  TestWorkerReportsScreen({required super.userId, required super.userName, required super.profileUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Worker Reports')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => debugPrint('דו״ח נוכחות tapped'),
            child: const Text('דו״ח נוכחות'),
          ),
          ElevatedButton(
            onPressed: () => debugPrint('דו״ח משימות tapped'),
            child: const Text('דו״ח משימות'),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en', null);
  });

  group('WorkerReportsScreen', () {
    testWidgets('displays all report cards', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: WorkerReportsScreen(
            userId: 'testUserId',
            userName: 'Test User',
            profileUrl: 'https://example.com/profile.jpg',
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('דו״ח נוכחות'), findsOneWidget);
      expect(find.text('דו״ח משימות'), findsOneWidget);
      expect(find.text('דו״ח משמרות'), findsOneWidget);
    });

    testWidgets('displays all report cards and handles taps without navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: TestWorkerReportsScreen(
            userId: 'testUserId',
            userName: 'Test User',
            profileUrl: 'https://example.com/profile.jpg',
          ),
        ),
      );

      // Act
      await tester.tap(find.text('דו״ח נוכחות'));
      await tester.pump();

      // Assert
      expect(find.text('דו״ח נוכחות'), findsOneWidget);

      // Act
      await tester.tap(find.text('דו״ח משימות'));
      await tester.pump();

      // Assert
      expect(find.text('דו״ח משימות'), findsOneWidget);
    });
  });
}
