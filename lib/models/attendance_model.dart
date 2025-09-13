import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecord {
  final DateTime clockIn;
  final DateTime clockOut;

  AttendanceRecord({
    required this.clockIn,
    required this.clockOut,
  });

  double get hoursWorked {
    final duration = clockOut.difference(clockIn).inMinutes / 60.0;
    return duration > 0 ? duration : 0.0;
  }

  Map<String, dynamic> toMap() => {
        'clockIn': Timestamp.fromDate(clockIn),
        'clockOut': Timestamp.fromDate(clockOut),
      };

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      clockIn: (map['clockIn'] is Timestamp)
          ? (map['clockIn'] as Timestamp).toDate()
          : DateTime.now(),
      clockOut: (map['clockOut'] is Timestamp)
          ? (map['clockOut'] as Timestamp).toDate()
          : DateTime.now(),
    );
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
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      year: map['year'] is int ? map['year'] : 0,
      month: map['month'] is int ? map['month'] : 0,
      sessions: (map['sessions'] is List)
          ? (map['sessions'] as List<dynamic>)
              .map((r) => AttendanceRecord.fromMap(r as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
