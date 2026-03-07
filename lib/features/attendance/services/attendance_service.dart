import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';

class AttendanceService {
  static Future<AttendanceModel?> getAttendanceForUserByMonth(
    String userId,
    DateTime month,
  ) async {
    final String docId = '${userId}_${month.year}_${month.month.toString().padLeft(2, '0')}';
    final docRef = FirebaseFirestore.instance
        .collection(AppConstants.attendanceCollection)
        .doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) return null;

    return AttendanceModel.fromMap(doc.data()!, docId);
  }

  /// Fetches attendance across all months covered by [start]..[end] and
  /// returns a synthetic [AttendanceModel] whose sessions fall within that range.
  static Future<AttendanceModel?> getAttendanceForUserByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // Enumerate every month touched by the range
    final months = <DateTime>[];
    var cur = DateTime(start.year, start.month);
    final last = DateTime(end.year, end.month);
    while (!cur.isAfter(last)) {
      months.add(cur);
      cur = DateTime(cur.year, cur.month + 1);
    }

    final results = await Future.wait(
      months.map((m) => getAttendanceForUserByMonth(userId, m)),
    );

    final sessions = <AttendanceRecord>[];
    String userName = '';
    String resolvedUserId = userId;

    for (final model in results) {
      if (model == null) continue;
      userName = model.userName;
      resolvedUserId = model.userId;
      sessions.addAll(
        model.sessions.where(
          (s) => !s.clockIn.isBefore(start) && !s.clockIn.isAfter(end),
        ),
      );
    }

    if (sessions.isEmpty && userName.isEmpty) return null;

    return AttendanceModel(
      id: '${userId}_range',
      userId: resolvedUserId,
      userName: userName,
      year: start.year,
      month: start.month,
      sessions: sessions,
    );
  }
}
