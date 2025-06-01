import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/utils/datetime_utils.dart';

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

  // ✅ Metadata fields
  final String createdBy;
  final Timestamp? createdAt;
  final String lastUpdatedBy;
  final Timestamp? lastUpdatedAt;
  final String status;
  final String cancelReason;
  final String shiftManager;

  // ✅ Tracking decisions
  final List<Map<String, dynamic>> assignedWorkerData;
  final List<Map<String, dynamic>> rejectedWorkerData;

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
    required this.createdBy,
    required this.createdAt,
    required this.lastUpdatedBy,
    required this.lastUpdatedAt,
    required this.status,
    required this.cancelReason,
    required this.shiftManager,
    required this.assignedWorkerData,
    required this.rejectedWorkerData,
  });

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
      createdBy: map['createdBy'] ?? '',
      createdAt: map['createdAt'],
      lastUpdatedBy: map['lastUpdatedBy'] ?? '',
      lastUpdatedAt: map['lastUpdatedAt'],
      status: map['status'] ?? 'active',
      cancelReason: map['cancelReason'] ?? '',
      shiftManager: map['shiftManager'] ?? '',
      assignedWorkerData: List<Map<String, dynamic>>.from(map['assignedWorkerData'] ?? []),
      rejectedWorkerData: List<Map<String, dynamic>>.from(map['rejectedWorkerData'] ?? []),
    );
  }

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
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'],
      lastUpdatedBy: data['lastUpdatedBy'] ?? '',
      lastUpdatedAt: data['lastUpdatedAt'],
      status: data['status'] ?? 'active',
      cancelReason: data['cancelReason'] ?? '',
      shiftManager: data['shiftManager'] ?? '',
      assignedWorkerData: List<Map<String, dynamic>>.from(data['assignedWorkerData'] ?? []),
      rejectedWorkerData: List<Map<String, dynamic>>.from(data['rejectedWorkerData'] ?? []),
    );
  }

  String get formattedDateWithDay {
    try {
      DateTime dateTime = DateFormat('dd/MM/yyyy').parse(date);
      String dayName = DateTimeUtils.getHebrewWeekdayName(dateTime.weekday);
      return "$dayName, ${DateTimeUtils.formatDate(dateTime)}";
    } catch (e) {
      print("Error parsing date in ShiftModel: $e");
      return date;
    }
  }

  DateTime get parsedDate {
    try {
      return DateFormat('dd/MM/yyyy').parse(date);
    } catch (e) {
      print("Error parsing date in ShiftModel: $e");
      return DateTime.now();
    }
  }

  int get weekNumber {
    DateTime dt = parsedDate;
    int dayOfYear = int.parse(DateFormat("D").format(dt));
    return ((dayOfYear - dt.weekday + 10) / 7).floor();
  }

  int get dayOfWeek => parsedDate.weekday;

  bool isInWeek(int targetWeek) => weekNumber == targetWeek;

  bool get isFull => assignedWorkers.length >= maxWorkers;

  bool isUserAssigned(String userId) => assignedWorkers.contains(userId);
}
