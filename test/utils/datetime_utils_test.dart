import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/utils/datetime_utils.dart';

void main() {
  group('DateTimeUtils', () {
    test('formatDate formats DateTime to dd/MM/yyyy', () {
      // Arrange
      final date = DateTime(2025, 9, 13); // September 13, 2025

      // Act
      final formattedDate = DateTimeUtils.formatDate(date);

      // Assert
      expect(formattedDate, '13/09/2025');
    });

    test('formatTime formats TimeOfDay to HH:mm', () {
      // Arrange
      final time = TimeOfDay(hour: 9, minute: 5); // 09:05

      // Act
      final formattedTime = DateTimeUtils.formatTime(time);

      // Assert
      expect(formattedTime, '09:05');
    });

    test('startOfWeek returns the start of the week (Sunday)', () {
      // Arrange
      final date = DateTime(2025, 9, 13); // Saturday, September 13, 2025

      // Act
      final startOfWeek = DateTimeUtils.startOfWeek(date);

      // Assert
      expect(startOfWeek, DateTime(2025, 9, 7)); // Sunday, September 7, 2025
    });

    test('formatDateWithDay formats date with Hebrew weekday name', () {
      // Arrange
      final date = '13/09/2025'; // Saturday, September 13, 2025

      // Act
      final formattedDate = DateTimeUtils.formatDateWithDay(date);

      // Assert
      expect(formattedDate, 'שבת, 13/09/2025');
    });

    test('getHebrewWeekdayName returns correct Hebrew weekday name', () {
      // Arrange
      final weekday = 6; // Saturday

      // Act
      final hebrewName = DateTimeUtils.getHebrewWeekdayName(weekday);

      // Assert
      expect(hebrewName, 'שבת');
    });

    test('formatDateWithDay handles invalid date gracefully', () {
      // Arrange
      final invalidDate = 'invalid-date';

      // Act
      final result = DateTimeUtils.formatDateWithDay(invalidDate);

      // Assert
      expect(result, invalidDate); // Should return the input as fallback
    });

    test('getHebrewWeekdayName returns empty string for invalid weekday', () {
      // Arrange
      final invalidWeekday = 8; // Out of range

      // Act
      final result = DateTimeUtils.getHebrewWeekdayName(invalidWeekday);

      // Assert
      expect(result, ''); // Should return an empty string
    });

    test('startOfWeek handles edge case for Sunday', () {
      // Arrange
      final sunday = DateTime(2025, 9, 7); // Sunday, September 7, 2025

      // Act
      final startOfWeek = DateTimeUtils.startOfWeek(sunday);

      // Assert
      expect(startOfWeek, sunday); // Should return the same date
    });
  });
}
