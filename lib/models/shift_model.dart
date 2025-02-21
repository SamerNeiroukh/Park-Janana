import 'package:park_janana/utils/datetime_utils.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String id;
  final String date;
  final String department;
  final String startTime;
  final String endTime;
  final int maxWorkers;
  final List<String> requestedWorkers;
  final List<String> assignedWorkers;
  final List<Map<String, dynamic>> messages;

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

  // ✅ New method to parse directly from Firestore snapshots
  factory ShiftModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return ShiftModel(
    id: doc.id,
    date: data['date'] ?? '',
    department: data['department'] ?? '',
    startTime: data['startTime'] ?? '',
    endTime: data['endTime'] ?? '',
    maxWorkers: data['maxWorkers'] ?? 0,
    requestedWorkers: List<String>.from(data['requestedWorkers'] ?? []),
    assignedWorkers: List<String>.from(data['assignedWorkers'] ?? []),
    messages: List<Map<String, dynamic>>.from(data['messages'] ?? []),
  );
}

  // 🟢 Formatted date with Hebrew weekday name
  String get formattedDateWithDay {
    try {
      DateTime dateTime = DateFormat('dd/MM/yyyy').parse(date);
      String dayName = DateTimeUtils.getHebrewWeekdayName(dateTime.weekday);
      return "$dayName, ${DateTimeUtils.formatDate(dateTime)}";
    } catch (e) {
      print("Error parsing date in ShiftModel: $e");
      return date; // Fallback to raw date if parsing fails
    }
  }

  // 🟢 Parse date for week filtering
  DateTime get parsedDate {
    try {
      return DateFormat('dd/MM/yyyy').parse(date);
    } catch (e) {
      print("Error parsing date in ShiftModel: $e");
      return DateTime.now();
    }
  }

  // ✅ Week number for weekly view
  int get weekNumber {
    DateTime dt = parsedDate;
    int dayOfYear = int.parse(DateFormat("D").format(dt));
    return ((dayOfYear - dt.weekday + 10) / 7).floor();
  }

  // ✅ Get weekday number (1 = Monday, 7 = Sunday)
  int get dayOfWeek => parsedDate.weekday;

  // ✅ Check if shift is in a specific week
  bool isInWeek(int targetWeek) => weekNumber == targetWeek;

  // ✅ Check if shift is full
  bool get isFull => assignedWorkers.length >= maxWorkers;

  // ✅ Check if current user is assigned
  bool isUserAssigned(String userId) => assignedWorkers.contains(userId);
}
