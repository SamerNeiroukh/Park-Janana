import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../utils/custom_exception.dart';
import 'firebase_service.dart';
import '../constants/app_constants.dart';

class ShiftService {
  final FirebaseService _firebaseService = FirebaseService();

  // 🟢 Fetch available shifts as a stream
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firebaseService.getShiftsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // 🟢 Create a new shift
  Future<void> createShift({
    required String date,
    required String startTime,
    required String endTime,
    required String department,
    required int maxWorkers,
  }) async {
    try {
      String shiftId = _firebaseService.generateDocumentId(AppConstants.shiftsCollection);
      await _firebaseService.createShift({
        'shift_id': shiftId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'department': department,
        'maxWorkers': maxWorkers,
        'assignedWorkers': [],
        'requestedWorkers': [],
        'messages': [], // ✅ Initialize messages list
      });
    } catch (e) {
      throw CustomException('שגיאה ביצירת משמרת.');
    }
  }

  Future<void> addMessageToShift(String shiftId, String message, String managerId) async {
  try {
    print("Firebase logs: Attempting to add message to shift -> $shiftId");

    DocumentReference shiftRef = FirebaseFirestore.instance.collection(AppConstants.shiftsCollection).doc(shiftId);
    DocumentSnapshot shiftDoc = await shiftRef.get();

    if (!shiftDoc.exists) {
      print("Firebase logs: Shift does not exist -> $shiftId");
      throw CustomException("המשמרת לא קיימת");
    }

    final shiftData = shiftDoc.data() as Map<String, dynamic>?;

    if (shiftData == null || !shiftData.containsKey('messages')) {
      print("Firebase logs: Initializing messages field for shift -> $shiftId");
      await shiftRef.update({'messages': []});
    }

    print("Firebase logs: Sending message -> $message");

    await shiftRef.update({
      'messages': FieldValue.arrayUnion([
        {
          'message': message,
          'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
          'senderId': managerId, // ✅ Store the manager ID
        }
      ])
    });

    print("Firebase logs: Message added successfully!");
  } catch (e) {
    print("Firebase logs: Error adding message -> $e");
    throw CustomException('שגיאה בהוספת הודעה למשמרת.');
  }
}
  // 🟢 Delete a shift
  Future<void> deleteShift(String shiftId) async {
    try {
      await _firebaseService.deleteShift(shiftId);
    } catch (e) {
      throw CustomException('שגיאה במחיקת המשמרת.');
    }
  }

  // 🟢 Request to join a shift
  Future<void> requestShift(String shiftId, String workerId) async {
    try {
      await _firebaseService.updateShift(shiftId, {
        'requestedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בשליחת בקשת הצטרפות למשמרת.');
    }
  }

  // 🟢 Cancel shift request
  Future<void> cancelShiftRequest(String shiftId, String workerId) async {
    try {
      await _firebaseService.updateShift(shiftId, {
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בביטול בקשת המשמרת.');
    }
  }

  // 🟢 Approve a worker for a shift
  Future<void> approveWorker(String shiftId, String workerId) async {
    try {
      await _firebaseService.updateShift(shiftId, {
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
      await _firebaseService.updateShift(shiftId, {
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בדחיית בקשת העובד.');
    }
  }

  // 🟢 Remove an assigned worker from a shift
  Future<void> removeWorker(String shiftId, String workerId) async {
    try {
      await _firebaseService.updateShift(shiftId, {
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בהסרת עובד מהמשמרת.');
    }
  }

  // 🟢 Fetch worker details for UI display
  Future<List<UserModel>> fetchWorkerDetails(List<String> workerIds) async {
    List<UserModel> workers = [];
    try {
      for (String workerId in workerIds) {
        final userDoc = await _firebaseService.getUser(workerId);
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
