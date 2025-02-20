import 'package:park_janana/utils/datetime_utils.dart';
import 'package:intl/intl.dart';

class ShiftModel {
  final String id;
  final String date;
  final String department;
  final String startTime;
  final String endTime;
  final int maxWorkers;
  final List<String> requestedWorkers;
  final List<String> assignedWorkers;
  final List<Map<String, dynamic>> messages; // ✅ Messages handled

  ShiftModel({
    required this.id,
    required this.date,
    required this.department,
    required this.startTime,
    required this.endTime,
    required this.maxWorkers,
    required this.requestedWorkers,
    required this.assignedWorkers,
    required this.messages,
  });

  // 🟢 Convert Firestore document to ShiftModel with null checks
  factory ShiftModel.fromMap(String id, Map<String, dynamic> map) {
    return ShiftModel(
      id: id,
      date: map['date'] ?? '',
      department: map['department'] ?? '',
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      maxWorkers: map['maxWorkers'] ?? 0,
      requestedWorkers: List<String>.from(map['requestedWorkers'] ?? []),
      assignedWorkers: List<String>.from(map['assignedWorkers'] ?? []),
      messages: List<Map<String, dynamic>>.from(map['messages'] ?? []),
    );
  }

  // 🟢 Formatted date with Hebrew weekday name
  String get formattedDateWithDay {
    try {
      // ✅ Parse using dd/MM/yyyy format
      DateTime dateTime = DateFormat('dd/MM/yyyy').parse(date);
      String dayName = DateTimeUtils.getHebrewWeekdayName(dateTime.weekday);
      return "$dayName, ${DateTimeUtils.formatDate(dateTime)}";
    } catch (e) {
      print("Error parsing date in ShiftModel: $e");
      return date; // Fallback to raw date if parsing fails
    }
  }
}
