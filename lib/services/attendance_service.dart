import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/attendance_model.dart';

class AttendanceService {
  static Future<AttendanceModel?> getAttendanceForUserByMonth(
    String userId,
    DateTime month,
  ) async {
    final String docId = '${userId}_${month.year}_${month.month.toString().padLeft(2, '0')}';
    final docRef = FirebaseFirestore.instance
        .collection('attendance_logs')
        .doc(docId);

    final doc = await docRef.get();
    if (!doc.exists) return null;

    return AttendanceModel.fromMap(doc.data()!, docId);
  }
}
