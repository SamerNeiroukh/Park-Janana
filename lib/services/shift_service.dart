import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../utils/custom_exception.dart';
import 'firebase_service.dart';
import '../constants/app_constants.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ShiftService {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

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

  Stream<List<ShiftModel>> getShiftsStream() {
    return _firebaseService.getShiftsStream().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

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

  List<ShiftModel> sortShifts(List<ShiftModel> shifts, String sortOption) {
    if (sortOption == 'תאריך') {
      shifts.sort((a, b) => DateFormat('dd/MM/yyyy').parse(a.date).compareTo(DateFormat('dd/MM/yyyy').parse(b.date)));
    } else if (sortOption == 'מחלקה') {
      shifts.sort((a, b) => a.department.compareTo(b.department));
    }
    shifts.sort((a, b) => a.startTime.compareTo(b.startTime));
    return shifts;
  }

  Future<void> createShift({
    required String date,
    required String startTime,
    required String endTime,
    required String department,
    required int maxWorkers,
  }) async {
    try {
      final String shiftId = _firebaseService.generateDocumentId(AppConstants.shiftsCollection);
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

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
        'createdBy': currentUserId,
        'createdAt': Timestamp.now(),
        'lastUpdatedBy': currentUserId,
        'lastUpdatedAt': Timestamp.now(),
        'status': 'active',
        'cancelReason': '',
        'assignedWorkerData': [],
        'rejectedWorkerData': [],
        'shiftManager': '',
      });
    } catch (e) {
      throw CustomException('שגיאה ביצירת משמרת.');
    }
  }

  Future<void> addMessageToShift(String shiftId, String message, String managerId) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      DocumentSnapshot shiftDoc = await shiftRef.get();

      if (!shiftDoc.exists) throw CustomException("המשמרת לא קיימת");

      final shiftData = shiftDoc.data() as Map<String, dynamic>?;

      if (shiftData == null || !shiftData.containsKey('messages')) {
        await shiftRef.update({'messages': []});
      }

      await shiftRef.update({
        'messages': FieldValue.arrayUnion([
          {
            'message': message,
            'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
            'senderId': managerId,
          }
        ])
      });
    } catch (e) {
      throw CustomException('שגיאה בהוספת הודעה למשמרת.');
    }
  }

  Future<void> deleteShift(String shiftId) async {
    try {
      await _firebaseService.deleteShift(shiftId);
    } catch (e) {
      throw CustomException('שגיאה במחיקת המשמרת.');
    }
  }

  Future<void> requestShift(String shiftId, String workerId) async {
    try {
      await _firebaseService.updateShift(shiftId, {
        'requestedWorkers': FieldValue.arrayUnion([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בשליחת בקשת הצטרפות למשמרת.');
    }
  }

  Future<void> cancelShiftRequest(String shiftId, String workerId) async {
    try {
      await _firebaseService.updateShift(shiftId, {
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
      });
    } catch (e) {
      throw CustomException('שגיאה בביטול בקשת המשמרת.');
    }
  }

Future<void> approveWorker(String shiftId, String workerId) async {
  final manager = FirebaseAuth.instance.currentUser;
  if (manager == null) throw CustomException("Manager not logged in");

  try {
    // 1. Fetch worker info
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(workerId).get();
    if (!userDoc.exists) throw CustomException("Worker not found");

    final userData = userDoc.data()!;
    final fullName = userData['fullName'] ?? '';
    final profilePicture = userData['profile_picture'] ?? '';
    final role = userData['role'] ?? 'worker';

    // 2. Get shift details for notification
    final shiftDoc = await FirebaseFirestore.instance.collection('shifts').doc(shiftId).get();
    final shiftData = shiftDoc.data();
    final shiftDate = shiftData?['date'] ?? '';
    final shiftTime = '${shiftData?['startTime'] ?? ''}-${shiftData?['endTime'] ?? ''}';
    final department = shiftData?['department'] ?? '';

    final decisionData = {
      'userId': workerId,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'decision': 'accepted',
      'decisionBy': manager.uid,
      'decisionAt': Timestamp.now(),
      'roleAtAssignment': role,
      'requestedAt': Timestamp.now(), // ✅ Optional: Replace with actual request time if tracked
    };

    await _firebaseService.updateShift(shiftId, {
      'requestedWorkers': FieldValue.arrayRemove([workerId]),
      'assignedWorkers': FieldValue.arrayUnion([workerId]),
      'assignedWorkerData': FieldValue.arrayUnion([decisionData]),
    });

    // 🆕 Send notification to approved worker
    await _notificationService.sendNotificationToUser(
      userId: workerId,
      title: 'אושרת להצטרף למשמרת!',
      body: 'אושרת להצטרפות למשמרת ב$department ב$shiftDate בשעות $shiftTime',
      type: 'shift_approved',
      additionalData: {
        'shiftId': shiftId,
        'date': shiftDate,
        'time': shiftTime,
        'department': department,
      },
    );

  } catch (e) {
    throw CustomException("שגיאה באישור העובד: $e");
  }
}

Future<void> rejectWorker(String shiftId, String workerId) async {
  final manager = FirebaseAuth.instance.currentUser;
  if (manager == null) throw CustomException("Manager not logged in");

  try {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(workerId).get();
    if (!userDoc.exists) throw CustomException("Worker not found");

    final userData = userDoc.data()!;
    final fullName = userData['fullName'] ?? '';
    final profilePicture = userData['profile_picture'] ?? '';
    final role = userData['role'] ?? 'worker';

    final decisionData = {
      'userId': workerId,
      'fullName': fullName,
      'profilePicture': profilePicture,
      'decision': 'rejected',
      'decisionBy': manager.uid,
      'decisionAt': Timestamp.now(),
      'roleAtAssignment': role,
      'requestedAt': Timestamp.now(),
    };

    await _firebaseService.updateShift(shiftId, {
      'requestedWorkers': FieldValue.arrayRemove([workerId]),
      'rejectedWorkerData': FieldValue.arrayUnion([decisionData]),
    });
  } catch (e) {
    throw CustomException("שגיאה בדחיית העובד: $e");
  }
}

  Future<void> removeWorker(String shiftId, String workerId) async {
  final manager = FirebaseAuth.instance.currentUser;
  if (manager == null) throw CustomException("Manager not logged in");

  try {
    DocumentReference shiftRef = _firestore.collection('shifts').doc(shiftId);
    DocumentSnapshot doc = await shiftRef.get();

    if (!doc.exists) throw CustomException("Shift not found");
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Get shift details for notification
    final shiftDate = data['date'] ?? '';
    final shiftTime = '${data['startTime'] ?? ''}-${data['endTime'] ?? ''}';
    final department = data['department'] ?? '';

    List<dynamic> currentAssignedData = data['assignedWorkerData'] ?? [];

    // Update the specific worker entry
    List<dynamic> updatedAssignedData = currentAssignedData.map((entry) {
      if (entry['userId'] == workerId) {
        return {
          ...entry,
          'decision': 'removed',
          'removedAt': Timestamp.now(),
          'removedBy': manager.uid,
        };
      }
      return entry;
    }).toList();

    await shiftRef.update({
      'assignedWorkers': FieldValue.arrayRemove([workerId]),
      'assignedWorkerData': updatedAssignedData,
    });

    // 🆕 Send notification to removed worker
    await _notificationService.sendNotificationToUser(
      userId: workerId,
      title: 'הוסרת מהמשמרת',
      body: 'הוסרת ממשמרת ב$department ב$shiftDate בשעות $shiftTime',
      type: 'shift_removed',
      additionalData: {
        'shiftId': shiftId,
        'date': shiftDate,
        'time': shiftTime,
        'department': department,
      },
    );

  } catch (e) {
    throw CustomException("שגיאה בהסרת העובד: $e");
  }
}

  Future<List<UserModel>> fetchWorkerDetails(List<String> workerIds) async {
    List<UserModel> workers = [];
    List<String> missingWorkerIds = [];

    for (String workerId in workerIds) {
      if (_workerCache.containsKey(workerId)) {
        workers.add(_workerCache[workerId]!);
      } else {
        missingWorkerIds.add(workerId);
      }
    }

    if (missingWorkerIds.isNotEmpty) {
      try {
        for (String workerId in missingWorkerIds) {
          final userDoc = await _firebaseService.getUser(workerId);
          if (userDoc.exists && userDoc.data() != null) {
            UserModel worker = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            _workerCache[workerId] = worker;
            workers.add(worker);
          }
        }
      } catch (e) {
        throw CustomException('שגיאה בשליפת נתוני העובדים.');
      }
    }

    return workers;
  }

  Future<void> updateMessage(String shiftId, int timestamp, String newMessage) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
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

  Future<void> deleteMessage(String shiftId, int timestamp) async {
    try {
      DocumentReference shiftRef = _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
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
