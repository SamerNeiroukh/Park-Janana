import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class WorkerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, UserModel> _workerCache = {};
  static const Duration _cacheTtl = Duration(minutes: 10);
  DateTime _cacheTimestamp = DateTime.now();

  void _checkCacheExpiry() {
    if (DateTime.now().difference(_cacheTimestamp) > _cacheTtl) {
      _workerCache.clear();
      _cacheTimestamp = DateTime.now();
    }
  }

  Future<void> approveWorker(String shiftId, String workerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw CustomException("משתמש לא מחובר");

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(workerId)
          .get();
      final userData = userDoc.data();

      if (userData == null) return;

      final assignedWorkerEntry = {
        'userId': workerId,
        'fullName': userData['fullName'] ?? '',
        'profilePicture': userData['profile_picture'] ?? '',
        'requestedAt': Timestamp.now(),
        'decision': 'accepted',
        'decisionBy': currentUser.uid,
        'decisionAt': Timestamp.now(),
        'roleAtAssignment': userData['role'] ?? 'worker',
        'uuid': DateTime.now().microsecondsSinceEpoch.toString(),
      };

      final shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkers': FieldValue.arrayUnion([workerId]),
        'assignedWorkerData': FieldValue.arrayUnion([assignedWorkerEntry]),
      });
    } catch (e) {
      throw CustomException('שגיאה באישור העובד למשמרת.');
    }
  }

  Future<void> rejectWorker(String shiftId, String workerId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw CustomException("משתמש לא מחובר");

      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(workerId)
          .get();
      final userData = userDoc.data();

      if (userData == null) return;

      final rejectionEntry = {
        'userId': workerId,
        'fullName': userData['fullName'] ?? '',
        'profilePicture': userData['profile_picture'] ?? '',
        'requestedAt': Timestamp.now(),
        'decision': 'rejected',
        'decisionBy': currentUser.uid,
        'decisionAt': Timestamp.now(),
        'roleAtAssignment': userData['role'] ?? 'worker',
        'uuid': DateTime.now().microsecondsSinceEpoch.toString(),
      };

      final shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove([workerId]),
        'rejectedWorkerData': FieldValue.arrayUnion([rejectionEntry]),
      });
    } catch (e) {
      throw CustomException('שגיאה בדחיית בקשת העובד.');
    }
  }

  Future<void> removeWorker(String shiftId, String workerId) async {
    try {
      final shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      final shiftSnap = await shiftRef.get();
      final shiftData = shiftSnap.data() as Map<String, dynamic>;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw CustomException("המשתמש לא מחובר");
      }

      final List<dynamic> assignedWorkerData =
          shiftData['assignedWorkerData'] ?? [];

      final List updatedWorkerData = assignedWorkerData.map((entry) {
        if (entry['userId'] == workerId) {
          return {
            ...entry,
            'decision': 'removed',
            'removedAt': Timestamp.now(),
            'removedBy': currentUser.uid,
          };
        }
        return entry;
      }).toList();

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkerData': updatedWorkerData,
      });
    } catch (e) {
      throw CustomException('שגיאה בהסרת עובד מהמשמרת.');
    }
  }

  Future<void> bulkApproveWorkers(
      String shiftId, List<String> workerIds) async {
    try {
      final DocumentReference shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'requestedWorkers': FieldValue.arrayRemove(workerIds),
        'assignedWorkers': FieldValue.arrayUnion(workerIds),
      });
    } catch (e) {
      throw Exception("שגיאה באישור העובדים למשמרת.");
    }
  }

  Future<void> assignWorkerToShift(String shiftId, String workerId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(workerId)
          .get();
      final userData = userDoc.data();

      if (userData == null) return;

      final user = UserModel.fromMap(userData);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final now = Timestamp.now();
      final assignedWorkerEntry = {
        'userId': user.uid,
        'fullName': user.fullName,
        'profilePicture': user.profilePicture,
        'requestedAt': now,
        'decision': 'accepted',
        'decisionBy': currentUser.uid,
        'decisionAt': now,
        'roleAtAssignment': user.role,
        'uuid': DateTime.now().microsecondsSinceEpoch.toString(),
      };

      final shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayUnion([workerId]),
        'assignedWorkerData': FieldValue.arrayUnion([assignedWorkerEntry]),
        'lastUpdatedBy': currentUser.uid,
        'lastUpdatedAt': now,
      });
    } catch (e) {
      debugPrint("Error assigning worker to shift: $e");
      throw CustomException("שגיאה בהוספת העובד למשמרת.");
    }
  }

  Future<void> removeWorkerFromShift(String shiftId, String workerId) async {
    try {
      final shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      final shiftSnap = await shiftRef.get();
      final shiftData = shiftSnap.data() as Map<String, dynamic>;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw CustomException("המשתמש לא מחובר");
      }

      final List<dynamic> assignedWorkerData =
          shiftData['assignedWorkerData'] ?? [];

      final List updatedWorkerData = assignedWorkerData.map((entry) {
        if (entry['userId'] == workerId) {
          return {
            ...entry,
            'decision': 'removed',
            'removedAt': Timestamp.now(),
            'removedBy': currentUser.uid,
          };
        }
        return entry;
      }).toList();

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
        'assignedWorkerData': updatedWorkerData,
        'lastUpdatedBy': currentUser.uid,
        'lastUpdatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint("Error removing worker from shift: $e");
      throw CustomException("שגיאה בהסרת העובד מהמשמרת.");
    }
  }

  Future<void> moveWorkerBackToRequested(
      String shiftId, String workerId) async {
    final manager = FirebaseAuth.instance.currentUser;
    if (manager == null) throw CustomException("Manager not logged in");

    try {
      final DocumentReference shiftRef =
          _firestore.collection(AppConstants.shiftsCollection).doc(shiftId);
      final DocumentSnapshot doc = await shiftRef.get();

      if (!doc.exists) throw CustomException("Shift not found");
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      final List<dynamic> currentAssignedData =
          data['assignedWorkerData'] ?? [];

      final List<dynamic> updatedAssignedData =
          currentAssignedData.map((entry) {
        if (entry['userId'] == workerId) {
          return {
            ...entry,
            'decision': 'undo',
            'undoAt': Timestamp.now(),
            'undoBy': manager.uid,
          };
        }
        return entry;
      }).toList();

      await shiftRef.update({
        'assignedWorkers': FieldValue.arrayRemove([workerId]),
        'requestedWorkers': FieldValue.arrayUnion([workerId]),
        'assignedWorkerData': updatedAssignedData,
      });
    } catch (e) {
      debugPrint("Error moving worker back to requested: $e");
      throw CustomException('שגיאה בהעברת העובד חזרה לרשימת המבקשים.');
    }
  }

  Future<UserModel?> getUserDetails(String userId) async {
    _checkCacheExpiry();
    if (_workerCache.containsKey(userId)) {
      return _workerCache[userId]!;
    }

    try {
      final DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      if (userDoc.exists) {
        final UserModel user =
            UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        _workerCache[userId] = user;
        return user;
      } else {
        debugPrint("User not found: $userId");
        return null;
      }
    } catch (e) {
      throw Exception("Error fetching user details: $e");
    }
  }

  /// Returns all approved users who can be assigned to a shift:
  /// both workers and managers.
  Future<List<UserModel>> fetchAllWorkers() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['worker', 'manager'])
          .where('approved', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Error fetching all workers: $e");
    }
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    _checkCacheExpiry();

    final List<UserModel> users = [];
    final List<String> missingIds = [];

    // Return cached users, collect missing IDs
    for (final id in userIds) {
      if (_workerCache.containsKey(id)) {
        users.add(_workerCache[id]!);
      } else {
        missingIds.add(id);
      }
    }

    // Batch-fetch missing users (whereIn supports up to 30)
    for (var i = 0; i < missingIds.length; i += 30) {
      final batch = missingIds.sublist(
        i,
        i + 30 > missingIds.length ? missingIds.length : i + 30,
      );
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snapshot.docs) {
        final user = UserModel.fromMap(doc.data());
        _workerCache[user.uid] = user;
        users.add(user);
      }
    }

    return users;
  }
}
