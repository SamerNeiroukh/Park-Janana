import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';

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
      final dateTime = DateFormat('dd/MM/yyyy').parse(date);
      final dayName = DateTimeUtils.getHebrewWeekdayName(dateTime.weekday);
      return "$dayName, ${DateTimeUtils.formatDate(dateTime)}";
    } catch (e) {
      debugPrint("Error parsing date in ShiftModel: $e");
      return date;
    }
  }

  DateTime get parsedDate {
    try {
      return DateFormat('dd/MM/yyyy').parse(date);
    } catch (e) {
      debugPrint("Error parsing date in ShiftModel: $e");
      return DateTime.now();
    }
  }

  int get weekNumber {
    final dt = parsedDate;
    final dayOfYear = int.parse(DateFormat("D").format(dt));
    return ((dayOfYear - dt.weekday + 10) / 7).floor();
  }

  int get dayOfWeek => parsedDate.weekday;

  bool isInWeek(int targetWeek) => weekNumber == targetWeek;

  bool get isFull => assignedWorkers.length >= maxWorkers;

  bool isUserAssigned(String userId) => assignedWorkers.contains(userId);

  // Create a copy of ShiftModel with some fields updated
  ShiftModel copyWith({
    String? id,
    String? date,
    String? department,
    String? startTime,
    String? endTime,
    int? maxWorkers,
    List<String>? requestedWorkers,
    List<String>? assignedWorkers,
    List<Map<String, dynamic>>? messages,
    String? createdBy,
    Timestamp? createdAt,
    String? lastUpdatedBy,
    Timestamp? lastUpdatedAt,
    String? status,
    String? cancelReason,
    String? shiftManager,
    List<Map<String, dynamic>>? assignedWorkerData,
    List<Map<String, dynamic>>? rejectedWorkerData,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      date: date ?? this.date,
      department: department ?? this.department,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxWorkers: maxWorkers ?? this.maxWorkers,
      requestedWorkers: requestedWorkers ?? this.requestedWorkers,
      assignedWorkers: assignedWorkers ?? this.assignedWorkers,
      messages: messages ?? this.messages,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      status: status ?? this.status,
      cancelReason: cancelReason ?? this.cancelReason,
      shiftManager: shiftManager ?? this.shiftManager,
      assignedWorkerData: assignedWorkerData ?? this.assignedWorkerData,
      rejectedWorkerData: rejectedWorkerData ?? this.rejectedWorkerData,
    );
  }

  @override
  String toString() {
    return 'ShiftModel(id: $id, date: $date, department: $department, startTime: $startTime, endTime: $endTime, maxWorkers: $maxWorkers, requestedWorkers: ${requestedWorkers.length} workers, assignedWorkers: ${assignedWorkers.length} workers, messages: ${messages.length} items, createdBy: $createdBy, createdAt: $createdAt, lastUpdatedBy: $lastUpdatedBy, lastUpdatedAt: $lastUpdatedAt, status: $status, cancelReason: $cancelReason, shiftManager: $shiftManager, assignedWorkerData: ${assignedWorkerData.length} items, rejectedWorkerData: ${rejectedWorkerData.length} items)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ShiftModel &&
        other.id == id &&
        other.date == date &&
        other.department == department &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.maxWorkers == maxWorkers &&
        listEquals(other.requestedWorkers, requestedWorkers) &&
        listEquals(other.assignedWorkers, assignedWorkers) &&
        _listOfMapsEquals(other.messages, messages) &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.lastUpdatedBy == lastUpdatedBy &&
        other.lastUpdatedAt == lastUpdatedAt &&
        other.status == status &&
        other.cancelReason == cancelReason &&
        other.shiftManager == shiftManager &&
        _listOfMapsEquals(other.assignedWorkerData, assignedWorkerData) &&
        _listOfMapsEquals(other.rejectedWorkerData, rejectedWorkerData);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        date.hashCode ^
        department.hashCode ^
        startTime.hashCode ^
        endTime.hashCode ^
        maxWorkers.hashCode ^
        requestedWorkers.hashCode ^
        assignedWorkers.hashCode ^
        messages.hashCode ^
        createdBy.hashCode ^
        createdAt.hashCode ^
        lastUpdatedBy.hashCode ^
        lastUpdatedAt.hashCode ^
        status.hashCode ^
        cancelReason.hashCode ^
        shiftManager.hashCode ^
        assignedWorkerData.hashCode ^
        rejectedWorkerData.hashCode;
  }

  // Helper method to compare List<Map<String, dynamic>>
  static bool _listOfMapsEquals(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!mapEquals(a[i], b[i])) return false;
    }
    return true;
  }
}
