import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/screens/shifts/weekly_schedule_screen.dart';
import 'package:park_janana/utils/datetime_utils.dart';

void main() {
  group('WeeklyScheduleScreen', () {
    testWidgets('should create without errors', (WidgetTester tester) async {
      // Test that WeeklyScheduleScreen can be instantiated
      const screen = WeeklyScheduleScreen();
      expect(screen, isA<WeeklyScheduleScreen>());
    });

    test('DateTimeUtils should provide Hebrew day names', () {
      // Test RTL Hebrew day name functionality
      expect(DateTimeUtils.getHebrewWeekdayName(1), equals('שני')); // Monday
      expect(DateTimeUtils.getHebrewWeekdayName(7), equals('ראשון')); // Sunday
      expect(DateTimeUtils.getHebrewWeekdayName(6), equals('שבת')); // Saturday
    });

    test('DateTimeUtils should format dates correctly', () {
      final testDate = DateTime(2023, 12, 25);
      final formatted = DateTimeUtils.formatDate(testDate);
      expect(formatted, equals('25/12/2023'));
    });

    test('DateTimeUtils should get start of week correctly', () {
      final testDate = DateTime(2023, 12, 25); // Monday
      final startOfWeek = DateTimeUtils.startOfWeek(testDate);
      
      // Start of week should be Sunday (weekday % 7 = 0)
      expect(startOfWeek.weekday % 7, equals(0));
      expect(startOfWeek.day, equals(24)); // Sunday Dec 24
    });
  });
}