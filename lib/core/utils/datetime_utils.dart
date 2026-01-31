import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  /// 🟢 Format DateTime to 'dd/MM/yyyy'
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// 🟢 Format TimeOfDay to 'HH:mm'
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// 🟢 Get the start of the current week (Sunday as the first day)
  static DateTime startOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday % 7));
  }

  /// 🟢 Format date with Hebrew weekday name
  static String formatDateWithDay(String date) {
    try {
      final DateTime dateTime = DateFormat('dd/MM/yyyy').parse(date);
      final String day = getHebrewWeekdayName(dateTime.weekday);
      return "$day, ${formatDate(dateTime)}";
    } catch (e) {
      debugPrint("Error parsing date: $e");
      return date; // Fallback if parsing fails
    }
  }

  /// 🟢 Get Hebrew weekday name (Sunday-first order)
  static String getHebrewWeekdayName(int weekday) {
    switch (weekday) {
      case 7:
        return 'ראשון';
      case 1:
        return 'שני';
      case 2:
        return 'שלישי';
      case 3:
        return 'רביעי';
      case 4:
        return 'חמישי';
      case 5:
        return 'שישי';
      case 6:
        return 'שבת';
      default:
        return '';
    }
  }
}
