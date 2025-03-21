import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/user_model.dart';
import '../utils/custom_exception.dart';
import '../constants/app_constants.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔵 Cache for storing worker details (reduces Firestore reads)
  final Map<String, UserModel> _workerCache = {};

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

  // 🟢 Bulk approve multiple workers for a shift
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

  // 🟢 Assign worker to a shift
  Future<void> assignWorkerToShift(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection('shifts').doc(shiftId);

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayUnion([workerId])
      });
    } catch (e) {
      print("Error assigning worker to shift: $e");
    }
  }

  // 🟢 Remove worker from a shift
  Future<void> removeWorkerFromShift(String shiftId, String workerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection('shifts').doc(shiftId);

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayRemove([workerId])
      });
    } catch (e) {
      print("Error removing worker from shift: $e");
    }
  }

  // 🟢 Get worker details with caching
  Future<UserModel> getUserDetails(String userId) async {
    // ✅ Check if user is already in cache
    if (_workerCache.containsKey(userId)) {
      return _workerCache[userId]!;
    }

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        UserModel user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        
        // ✅ Store in cache
        _workerCache[userId] = user;
        
        return user;
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      throw Exception("Error fetching user details: $e");
    }
  }

  Future<void> moveWorkerBackToRequested(String shiftId, String workerId) async {
  try {
    DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

    await shiftRef.update({
      'assignedWorkers': FieldValue.arrayRemove([workerId]), // ✅ Remove from assigned
      'requestedWorkers': FieldValue.arrayUnion([workerId]), // ✅ Add back to requested
    });
  } catch (e) {
    throw CustomException('שגיאה בהעברת העובד חזרה לרשימת המבקשים.');
  }
}
}
