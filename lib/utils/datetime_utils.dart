import 'package:flutter/material.dart'; // ✅ Import this
import 'package:intl/intl.dart';

class DateTimeUtils {
  /// Format DateTime to 'dd/MM/yyyy'
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format TimeOfDay to 'HH:mm'
  static String formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
