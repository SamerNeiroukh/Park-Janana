import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../utils/custom_exception.dart';
import 'firebase_service.dart';
import '../constants/app_constants.dart';
import 'package:intl/intl.dart';

class ShiftService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔵 Cache for storing worker details
  final Map<String, UserModel> _workerCache = {};

  Stream<List<ShiftModel>> getShiftsForWeek(DateTime startOfWeek) {
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _firestore
        .collection('shifts')
        .where('date', isGreaterThanOrEqualTo: DateFormat('dd/MM/yyyy').format(startOfWeek))
        .where('date', isLessThanOrEqualTo: DateFormat('dd/MM/yyyy').format(endOfWeek))
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ShiftModel.fromFirestore(doc)).toList());
  }

  // 🔵 Fetch available shifts as a stream
  Stream<List<ShiftModel>> getShiftsStream() {
    return _firebaseService.getShiftsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // ✅ Fetch shifts for a specific date
  Future<List<ShiftModel>> getShiftsByDate(DateTime date) async {
    try {
      final querySnapshot = await _firestore
          .collection('shifts')
          .where('date', isEqualTo: DateFormat('dd/MM/yyyy').format(date))
          .get();

      return querySnapshot.docs.map((doc) => ShiftModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw CustomException('שגיאה בשליפת המשמרות לתאריך זה.');
    }
  }

  // 🟢 Sort shifts by Date or Department
  List<ShiftModel> sortShifts(List<ShiftModel> shifts, String sortOption) {
    if (sortOption == 'תאריך') {
      // ✅ Sort by date (oldest first)
      shifts.sort((a, b) => DateFormat('dd/MM/yyyy').parse(a.date).compareTo(DateFormat('dd/MM/yyyy').parse(b.date)));
    } else if (sortOption == 'מחלקה') {
      // ✅ Sort by department
      shifts.sort((a, b) => a.department.compareTo(b.department));
    }
    // ✅ Sort by start time within the group
    shifts.sort((a, b) => a.startTime.compareTo(b.startTime));
    return shifts;
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
        'messages': [],
      });
    } catch (e) {
      throw CustomException('שגיאה ביצירת משמרת.');
    }
  }

  // 🟢 Add a message to a shift
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
            'senderId': managerId,
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

  // 🔵 Optimized method: Fetch worker details with caching
  Future<List<UserModel>> fetchWorkerDetails(List<String> workerIds) async {
    List<UserModel> workers = [];
    List<String> missingWorkerIds = [];

    // ✅ Check cache for existing workers
    for (String workerId in workerIds) {
      if (_workerCache.containsKey(workerId)) {
        workers.add(_workerCache[workerId]!);
      } else {
        missingWorkerIds.add(workerId);
      }
    }

    // ✅ Fetch only missing workers from Firestore
    if (missingWorkerIds.isNotEmpty) {
      try {
        for (String workerId in missingWorkerIds) {
          final userDoc = await _firebaseService.getUser(workerId);
          if (userDoc.exists && userDoc.data() != null) {
            UserModel worker = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            _workerCache[workerId] = worker; // ✅ Store in cache
            workers.add(worker);
          }
        }
      } catch (e) {
        throw CustomException('שגיאה בשליפת נתוני העובדים.');
      }
    }

    return workers;
  }

  // 🟢 Update message in shift
  Future<void> updateMessage(String shiftId, int timestamp, String newMessage) async {
    try {
      DocumentReference shiftRef = FirebaseFirestore.instance.collection(AppConstants.shiftsCollection).doc(shiftId);
      DocumentSnapshot shiftDoc = await shiftRef.get();

      if (!shiftDoc.exists) throw CustomException("המשמרת לא קיימת");

      List messages = List.from(shiftDoc['messages'] ?? []);
      int index = messages.indexWhere((msg) => msg['timestamp'] == timestamp);
      if (index != -1) {
        messages[index]['message'] = newMessage;
        await shiftRef.update({'messages': messages});
      }
    } catch (e) {
      throw CustomException('שגיאה בעדכון ההודעה.');
    }
  }

  // 🟢 Delete message from shift
  Future<void> deleteMessage(String shiftId, int timestamp) async {
    try {
      DocumentReference shiftRef = FirebaseFirestore.instance.collection(AppConstants.shiftsCollection).doc(shiftId);
      DocumentSnapshot shiftDoc = await shiftRef.get();

      if (!shiftDoc.exists) throw CustomException("המשמרת לא קיימת");

      List messages = List.from(shiftDoc['messages'] ?? []);
      messages.removeWhere((msg) => msg['timestamp'] == timestamp);
      await shiftRef.update({'messages': messages});
    } catch (e) {
      throw CustomException('שגיאה במחיקת ההודעה.');
    }
  }

  Future<List<ShiftModel>> getShiftsByWeek(DateTime weekStart) async {
  final weekEnd = weekStart.add(Duration(days: 6));
  final querySnapshot = await FirebaseFirestore.instance
      .collection('shifts')
      .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(weekStart))
      .where('date', isLessThanOrEqualTo: DateFormat('yyyy-MM-dd').format(weekEnd))
      .get();

  return querySnapshot.docs.map((doc) => ShiftModel.fromFirestore(doc)).toList();
}
}
