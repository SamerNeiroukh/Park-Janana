import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_constants.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../utils/custom_exception.dart';

class ShiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch available shifts as a stream
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firestore.collection(AppConstants.shiftsCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Request to join a shift
  Future<void> requestShift(String shiftId, String workerId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).update({
        'requestedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בשליחת בקשת הצטרפות למשמרת.');
    }
  }

  // Cancel shift request
  Future<void> cancelShiftRequest(String shiftId, String workerId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בביטול בקשת המשמרת.');
    }
  }

  // Create a new shift
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
      throw CustomException('שגיאה ביצירת משמרת חדשה.');
    }
  }

  // Delete a shift
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).delete();
    } catch (e) {
      throw CustomException('שגיאה במחיקת משמרת.');
    }
  }

  // Approve a worker for a shift
  Future<void> approveWorker(String shiftId, String workerId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה באישור העובד למשמרת.');
    }
  }

  // Reject a worker's request
  Future<void> rejectWorker(String shiftId, String workerId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בדחיית בקשת העובד.');
    }
  }

  // Remove an assigned worker from a shift
  Future<void> removeWorker(String shiftId, String workerId) async {
    try {
      await _firestore.collection(AppConstants.shiftsCollection).doc(shiftId).update({
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בהסרת עובד מהמשמרת.');
    }
  }

  // Fetch worker details for UI display
  Future<List<UserModel>> fetchWorkerDetails(List<String> workerIds) async {
    List<UserModel> workers = [];
    try {
      for (String workerId in workerIds) {
        DocumentSnapshot userDoc = await _firestore.collection(AppConstants.usersCollection).doc(workerId).get();
        if (userDoc.exists && userDoc.data() != null) {
          workers.add(UserModel.fromMap(userDoc.data() as Map<String, dynamic>));
        }
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת נתוני העובדים.');
    }
    return workers;
  }
}
