import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';

class ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all available shifts as a Stream (For workers to view in real-time)
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firestore.collection('shifts').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
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
