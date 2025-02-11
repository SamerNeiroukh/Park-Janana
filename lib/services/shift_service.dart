import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_constants.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart'; // ✅ Import user model for worker details

class ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all available shifts as a Stream (For workers to view in real-time)
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firestore.collection(AppConstants.shiftsCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  /// Request to join a shift (Worker action)
  Future<void> requestShift(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
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
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      print("Error canceling shift request: $e");
    }
  }

  /// Create a new shift (Manager only)
  Future<void> createShift({required String date, required String startTime, required String endTime, required String department, required int maxWorkers}) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc();
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

  /// Delete a shift (Manager action)
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).delete();
      print("✅ Shift $shiftId deleted successfully.");
    } catch (e) {
      print("Error deleting shift: $e");
    }
  }

  /// Approve a worker for a shift (Move from `requestedWorkers` to `assignedWorkers`)
  Future<void> approveWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      print("Error approving worker: $e");
    }
  }

  /// Reject a worker's request (Remove from `requestedWorkers`)
  Future<void> rejectWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      print("Error rejecting worker: $e");
    }
  }


  /// Remove an assigned worker from a shift
  Future<void> removeWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      print("Error removing worker: $e");
    }
  }

  /// Fetch worker details (Name & Profile Picture) for displaying in UI
  Future<List<UserModel>> fetchWorkerDetails(List<String> workerIds) async {
    List<UserModel> workers = [];
    try {
      for (String workerId in workerIds) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(workerId).get();
        if (userDoc.exists && userDoc.data() != null) {
          workers.add(UserModel.fromMap(userDoc.data() as Map<String, dynamic>));
        }
      }
    } catch (e) {
      print("Error fetching worker details: $e");
    }
    return workers;
  }
}
