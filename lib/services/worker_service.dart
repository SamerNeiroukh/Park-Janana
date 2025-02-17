import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/custom_exception.dart';
import '../constants/app_constants.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🟢 Approve a worker for a shift
  Future<void> approveWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה באישור העובד למשמרת.');
    }
  }

  // 🟢 Reject a worker's request
  Future<void> rejectWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בדחיית בקשת העובד.');
    }
  }

  // 🟢 Remove an assigned worker from a shift
   Future<void> removeWorker(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בהסרת עובד מהמשמרת.');
    }
  }



  Future<void> bulkApproveWorkers(String shiftId, List<String> workerIds) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove(workerIds),
        'assignedWorkers': FieldValue.arrayUnion(workerIds),
      });
    } catch (e) {
      throw Exception("שגיאה באישור העובדים למשמרת.");
    }
  }
}






