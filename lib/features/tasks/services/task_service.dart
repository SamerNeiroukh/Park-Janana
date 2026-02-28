import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = AppConstants.tasksCollection;

  // Create a new task
  Future<void> createTask(TaskModel task) async {
    try {
      final data = task.toMap();
      data['updatedAt'] = Timestamp.now();
      data['activityLog'] = [
        {
          'action': 'created',
          'by': task.createdBy,
          'timestamp': Timestamp.now(),
          'details': 'המשימה נוצרה',
        }
      ];
      await _firestore.collection(_collection).doc(task.id).set(data);
    } catch (e) {
      throw CustomException('שגיאה ביצירת משימה.');
    }
  }

  // Get tasks assigned to a specific worker (live stream)
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedTo', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Get tasks created by a manager
  Stream<List<TaskModel>> getTasksCreatedBy(String creatorId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: creatorId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Update general task status (manager only)
  Future<void> updateTaskStatus(String taskId, String status, String userId) async {
    try {
      final ref = _firestore.collection(_collection).doc(taskId);
      await ref.update({
        'status': status,
        'updatedAt': Timestamp.now(),
        'activityLog': FieldValue.arrayUnion([
          {
            'action': 'status_changed',
            'by': userId,
            'timestamp': Timestamp.now(),
            'details': 'סטטוס המשימה שונה ל-$status',
          }
        ]),
      });
    } catch (e) {
      throw CustomException('שגיאה בעדכון סטטוס המשימה.');
    }
  }

  // Add a comment
  Future<void> addComment(String taskId, Map<String, dynamic> comment) async {
    try {
      final ref = _firestore.collection(_collection).doc(taskId);
      await ref.update({
        'comments': FieldValue.arrayUnion([comment]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw CustomException('שגיאה בהוספת תגובה.');
    }
  }

  // Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      throw CustomException('שגיאה במחיקת המשימה.');
    }
  }

  // Update entire task with partial data
  Future<void> updateTask(String taskId, Map<String, dynamic> updatedData) async {
    try {
      updatedData['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(taskId).update(updatedData);
    } catch (e) {
      throw CustomException('שגיאה בעדכון המשימה.');
    }
  }

  // Log an activity entry
  Future<void> logActivity(String taskId, {
    required String action,
    required String by,
    required String details,
  }) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update({
        'activityLog': FieldValue.arrayUnion([
          {
            'action': action,
            'by': by,
            'timestamp': Timestamp.now(),
            'details': details,
          }
        ]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Failed to log activity: $e');
    }
  }

  // Update only the specific worker's entry in workerProgress
  Future<void> updateWorkerStatus(String taskId, String userId, String newStatus) async {
    final taskRef = _firestore.collection(_collection).doc(taskId);
    final snapshot = await taskRef.get();

    if (!snapshot.exists) {
      debugPrint('Task not found: $taskId');
      return;
    }

    final data = snapshot.data()!;
    final now = Timestamp.now();

    final workerProgress = Map<String, dynamic>.from(data['workerProgress'] ?? {});

    final progressEntry = Map<String, dynamic>.from(
      workerProgress[userId] ?? {
        'submittedAt': now,
        'startedAt': null,
        'endedAt': null,
        'status': 'pending',
      },
    );

    progressEntry['status'] = newStatus;
    if (newStatus == 'pending') {
      progressEntry['submittedAt'] = now;
    } else if (newStatus == 'in_progress') {
      progressEntry['startedAt'] = now;
    } else if (newStatus == 'pending_review') {
      progressEntry['submittedForReviewAt'] = now;
    } else if (newStatus == 'done') {
      progressEntry['endedAt'] = now;
    }

    workerProgress[userId] = progressEntry;

    final allStatuses = workerProgress.values
        .map((entry) => (entry as Map<String, dynamic>)['status'] as String)
        .toList();

    String overallStatus;
    if (allStatuses.every((s) => s == 'done')) {
      overallStatus = 'done';
    } else if (allStatuses.any(
        (s) => s == 'in_progress' || s == 'done' || s == 'pending_review')) {
      overallStatus = 'in_progress';
    } else {
      overallStatus = 'pending';
    }

    String actionDetails;
    switch (newStatus) {
      case 'in_progress':
        actionDetails = 'עובד התחיל לעבוד על המשימה';
        break;
      case 'pending_review':
        actionDetails = 'עובד שלח את המשימה לאישור מנהל';
        break;
      case 'done':
        actionDetails = 'עובד סיים את המשימה';
        break;
      default:
        actionDetails = 'סטטוס עובד עודכן';
    }

    await taskRef.update({
      'workerProgress.$userId': progressEntry,
      'status': overallStatus,
      'updatedAt': now,
      'activityLog': FieldValue.arrayUnion([
        {
          'action': 'worker_$newStatus',
          'by': userId,
          'timestamp': now,
          'details': actionDetails,
        }
      ]),
    });
  }

  /// Called by the task creator (manager) to approve a worker's completed work.
  /// Moves that worker from [pending_review] → [done] and recalculates the
  /// overall task status.
  Future<void> approveWorkerTask(
      String taskId, String workerId, String managerId) async {
    final taskRef = _firestore.collection(_collection).doc(taskId);
    final snapshot = await taskRef.get();
    if (!snapshot.exists) return;

    final data = snapshot.data()!;
    final now = Timestamp.now();

    final workerProgress =
        Map<String, dynamic>.from(data['workerProgress'] ?? {});
    final progressEntry = Map<String, dynamic>.from(
        workerProgress[workerId] ?? {'status': 'pending_review'});

    progressEntry['status'] = 'done';
    progressEntry['endedAt'] = now;
    progressEntry['approvedAt'] = now;
    progressEntry['approvedBy'] = managerId;

    workerProgress[workerId] = progressEntry;

    final allStatuses = workerProgress.values
        .map((e) => (e as Map<String, dynamic>)['status'] as String)
        .toList();

    String overallStatus;
    if (allStatuses.every((s) => s == 'done')) {
      overallStatus = 'done';
    } else if (allStatuses.any(
        (s) => s == 'in_progress' || s == 'done' || s == 'pending_review')) {
      overallStatus = 'in_progress';
    } else {
      overallStatus = 'pending';
    }

    await taskRef.update({
      'workerProgress.$workerId': progressEntry,
      'status': overallStatus,
      'updatedAt': now,
      'activityLog': FieldValue.arrayUnion([
        {
          'action': 'worker_approved',
          'by': managerId,
          'timestamp': now,
          'details': 'המנהל אישר את סיום המשימה לעובד',
        }
      ]),
    });
  }

  // Get task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _firestore.collection(_collection).doc(taskId).get();
    if (doc.exists) {
      return TaskModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Get single task stream
  Stream<TaskModel?> getTaskStream(String taskId) {
    return _firestore
        .collection(_collection)
        .doc(taskId)
        .snapshots()
        .map((doc) => doc.exists ? TaskModel.fromMap(doc.id, doc.data()!) : null);
  }

  // Get tasks assigned to a user by selected month
  static Future<List<TaskModel>> getTasksForUserByMonth(String userId, DateTime month) async {
    try {
      final firstDay = DateTime(month.year, month.month, 1);
      final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      final query = await FirebaseFirestore.instance
          .collection(AppConstants.tasksCollection)
          .where('assignedTo', arrayContains: userId)
          .where('dueDate', isGreaterThanOrEqualTo: firstDay)
          .where('dueDate', isLessThanOrEqualTo: lastDay)
          .get();

      final tasks = query.docs.map((doc) {
        final data = doc.data();
        return TaskModel.fromMap(doc.id, data);
      }).toList();

      return tasks;
    } catch (e) {
      debugPrint('Error fetching tasks for month: $e');
      return [];
    }
  }
}
