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

  /// 🟢 Format date with Hebrew weekday name
  static String formatDateWithDay(String date) {
    try {
      DateTime dateTime = DateFormat('dd/MM/yyyy').parse(date);
      String day = getHebrewWeekdayName(dateTime.weekday);
      return "$day, ${formatDate(dateTime)}";
    } catch (e) {
      print("Error parsing date: $e");
      return date; // Fallback if parsing fails
    }
  }

  /// 🟢 Get Hebrew weekday name
  static String getHebrewWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'יום שני';
      case 2:
        return 'יום שלישי';
      case 3:
        return 'יום רביעי';
      case 4:
        return 'יום חמישי';
      case 5:
        return 'יום שישי';
      case 6:
        return 'שבת';
      case 7:
        return 'יום ראשון';
      default:
        return '';
    }
  }
}
