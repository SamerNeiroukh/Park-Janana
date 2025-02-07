import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new shift (Manager only)
  Future<void> createShift({
    required String date,
    required String startTime,
    required String endTime,
    required String department,
    required int maxWorkers,
  }) async {
    try {
      DocumentReference shiftRef = _firestore.collection('shifts').doc();
      await shiftRef.set({
        'shift_id': shiftRef.id,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'department': department,
        'maxWorkers': maxWorkers,
        'assignedWorkers': [],
        'requestedWorkers': [],
      });
    } catch (e) {
      print("Error creating shift: $e");
    }
  }

  /// Fetch all available shifts (For workers to view)
  Future<List<Map<String, dynamic>>> getAvailableShifts() async {
    try {
      QuerySnapshot snapshot =
          await _firestore.collection('shifts').get();

      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      print("Error fetching shifts: $e");
      return [];
    }
  }

  /// Request to join a shift (Worker action)
  Future<void> requestShift(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection('shifts').doc(shiftId);
      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      print("Error requesting shift: $e");
    }
  }

  /// Cancel shift request (Worker action)
  Future<void> cancelShiftRequest(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection('shifts').doc(shiftId);
      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      print("Error canceling shift request: $e");
    }
  }

  /// Approve a worker for a shift (Manager action)
  Future<void> approveWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection('shifts').doc(shiftId);
      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      print("Error approving worker: $e");
    }
  }
}
