import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AttendanceRecord {
  final DateTime clockIn;
  final DateTime clockOut;

  AttendanceRecord({
    required this.clockIn,
    required this.clockOut,
  });

  double get hoursWorked =>
      clockOut.difference(clockIn).inMinutes / 60.0;

  Map<String, dynamic> toMap() => {
        'clockIn': Timestamp.fromDate(clockIn),
        'clockOut': Timestamp.fromDate(clockOut),
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      clockIn: (map['clockIn'] as Timestamp).toDate(),
      clockOut: (map['clockOut'] as Timestamp).toDate(),
    );
  }

  // Create a copy of AttendanceRecord with some fields updated
  AttendanceRecord copyWith({
    DateTime? clockIn,
    DateTime? clockOut,
  }) {
    return AttendanceRecord(
      clockIn: clockIn ?? this.clockIn,
      clockOut: clockOut ?? this.clockOut,
    );
  }

  @override
  String toString() {
    return 'AttendanceRecord(clockIn: $clockIn, clockOut: $clockOut, hoursWorked: ${hoursWorked.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceRecord &&
        other.clockIn == clockIn &&
        other.clockOut == clockOut;
  }

  @override
  int get hashCode {
    return clockIn.hashCode ^ clockOut.hashCode;
  }
}

class AttendanceModel {
  final String id; // document ID, e.g. userId_2025_05
  final String userId;
  final String userName;
  final int year;
  final int month;
  final List<AttendanceRecord> sessions;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.year,
    required this.month,
    required this.sessions,
  });

  int get daysWorked {
    final uniqueDays = sessions.map((r) => r.clockIn.day).toSet();
    return uniqueDays.length;
  }

  double get totalHoursWorked {
    return sessions.fold(0.0, (sum, r) => sum + r.hoursWorked);
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'year': year,
      'month': month,
      'sessions': sessions.map((r) => r.toMap()).toList(),
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      userId: map['userId'],
      userName: map['userName'],
      year: map['year'],
      month: map['month'],
      sessions: (map['sessions'] as List<dynamic>)
          .map((r) => AttendanceRecord.fromMap(r as Map<String, dynamic>))
          .toList(),
    );
  }

  // Create a copy of AttendanceModel with some fields updated
  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    int? year,
    int? month,
    List<AttendanceRecord>? sessions,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      year: year ?? this.year,
      month: month ?? this.month,
      sessions: sessions ?? this.sessions,
    );
  }

  @override
  String toString() {
    return 'AttendanceModel(id: $id, userId: $userId, userName: $userName, year: $year, month: $month, sessions: ${sessions.length} items, daysWorked: $daysWorked, totalHours: ${totalHoursWorked.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceModel &&
        other.id == id &&
        other.userId == userId &&
        other.userName == userName &&
        other.year == year &&
        other.month == month &&
        listEquals(other.sessions, sessions);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        userName.hashCode ^
        year.hashCode ^
        month.hashCode ^
        sessions.hashCode;
  }
}
