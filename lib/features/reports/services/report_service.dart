import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';

class ReportService {
  /// Get all shifts that the worker was involved in (even if removed) in a specific month
  static Future<List<ShiftModel>> getShiftsForWorkerByMonth({
    required String userId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = endOfMonth.day;

    // Generate all date strings for the month in dd/MM/yyyy format
    final allDates = List.generate(
      daysInMonth,
      (i) => DateFormat('dd/MM/yyyy').format(startOfMonth.add(Duration(days: i))),
    );

    // Firestore whereIn supports up to 30 values — batch if needed
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];
    for (var i = 0; i < allDates.length; i += 30) {
      final batch = allDates.sublist(i, i + 30 > allDates.length ? allDates.length : i + 30);
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.shiftsCollection)
          .where('date', whereIn: batch)
          .get();
      allDocs.addAll(snapshot.docs);
    }

    final List<ShiftModel> relevantShifts = [];
    for (var doc in allDocs) {
      final data = doc.data();
      final assignedData = List<Map<String, dynamic>>.from(data['assignedWorkerData'] ?? []);
      final wasInvolved = assignedData.any((d) => d['userId'] == userId);

      if (wasInvolved) {
        relevantShifts.add(ShiftModel.fromFirestore(doc));
      }
    }

    return relevantShifts;
  }

  /// Get attendance records for ALL workers in a given month (for manager general reports).
  ///
  /// Avoids a collection-wide query on attendance_logs (which Firestore rules block
  /// for non-owner callers). Instead:
  ///   1. Fetch all approved user UIDs from the users collection (permitted for managers).
  ///   2. Construct each attendance doc ID ({uid}_{year}_{month}) and read individually.
  static Future<List<AttendanceModel>> getAllWorkersAttendanceByMonth({
    required int year,
    required int month,
  }) async {
    // Step 1 – get all approved user UIDs + their authoritative names
    final usersSnapshot = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .where('approved', isEqualTo: true)
        .get();

    final uids = usersSnapshot.docs.map((d) => d.id).toList();
    if (uids.isEmpty) return [];

    // Build uid → fullName map so we can fix stale/missing names in attendance docs
    final nameMap = {
      for (final doc in usersSnapshot.docs)
        doc.id: (doc.data()['fullName'] as String? ?? '').trim(),
    };

    // Step 2 – fetch each attendance doc individually using the known ID pattern
    final paddedMonth = month.toString().padLeft(2, '0');
    final docFutures = uids.map((uid) => FirebaseFirestore.instance
        .collection(AppConstants.attendanceCollection)
        .doc('${uid}_${year}_$paddedMonth')
        .get());

    final docs = await Future.wait(docFutures);

    return docs
        .where((doc) => doc.exists)
        .map((doc) {
          final model = AttendanceModel.fromMap(doc.data()!, doc.id);
          final canonicalName = nameMap[model.userId] ?? '';
          // Replace stale/empty/unknown name with the live value from users collection
          if (canonicalName.isNotEmpty &&
              (model.userName.isEmpty || model.userName == 'Unknown')) {
            return model.copyWith(userName: canonicalName);
          }
          return model;
        })
        .toList();
  }

  /// Get all tasks due in a given month (for manager general reports)
  static Future<List<TaskModel>> getAllTasksByMonth({
    required int year,
    required int month,
  }) async {
    final start = Timestamp.fromDate(DateTime(year, month, 1));
    final end = Timestamp.fromDate(DateTime(year, month + 1, 1));
    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.tasksCollection)
        .where('dueDate', isGreaterThanOrEqualTo: start)
        .where('dueDate', isLessThan: end)
        .get();
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  /// Get ALL shifts in a given month without filtering by worker (for manager general reports)
  static Future<List<ShiftModel>> getAllShiftsByMonth({
    required int year,
    required int month,
  }) async {
    final startOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final allDates = List.generate(
      daysInMonth,
      (i) => DateFormat('dd/MM/yyyy').format(startOfMonth.add(Duration(days: i))),
    );

    final List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];
    for (var i = 0; i < allDates.length; i += 30) {
      final batch = allDates.sublist(
          i, i + 30 > allDates.length ? allDates.length : i + 30);
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.shiftsCollection)
          .where('date', whereIn: batch)
          .get();
      allDocs.addAll(snapshot.docs);
    }

    return allDocs.map((doc) => ShiftModel.fromFirestore(doc)).toList();
  }
}
