import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';

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
}
