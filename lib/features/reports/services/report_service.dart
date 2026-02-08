import 'package:cloud_firestore/cloud_firestore.dart';
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

    final snapshot = await FirebaseFirestore.instance
        .collection(AppConstants.shiftsCollection)
        .get(); // Removed server-side filter for full inclusion

    final List<ShiftModel> relevantShifts = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final shiftDateStr = data['date']; // Expected format: dd/MM/yyyy

      try {
        final parts = shiftDateStr.split('/');
        final parsedDate = DateTime.parse('${parts[2]}-${parts[1]}-${parts[0]}');

        if (parsedDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            parsedDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
          
          final assignedData = List<Map<String, dynamic>>.from(data['assignedWorkerData'] ?? []);
          final wasInvolved = assignedData.any((d) => d['userId'] == userId);

          if (wasInvolved) {
            relevantShifts.add(
              ShiftModel(
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
                lastUpdatedBy: data['lastUpdatedBy'] ?? '',
                status: data['status'] ?? '',
                cancelReason: data['cancelReason'] ?? '',
                createdAt: data['createdAt'],
                lastUpdatedAt: data['lastUpdatedAt'],
                assignedWorkerData: assignedData,
                rejectedWorkerData: List<Map<String, dynamic>>.from(data['rejectedWorkerData'] ?? []),
                shiftManager: data['shiftManager'] ?? '',
              ),
            );
          }
        }
      } catch (e) {
        continue; // Skip invalid dates
      }
    }

    return relevantShifts;
  }
}
