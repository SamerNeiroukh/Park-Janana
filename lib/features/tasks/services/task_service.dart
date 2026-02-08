import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = AppConstants.tasksCollection;

  // 🟢 Create a new task
  Future<void> createTask(TaskModel task) async {
    try {
      await _firestore.collection(_collection).doc(task.id).set(task.toMap());
    } catch (e) {
      throw CustomException('שגיאה ביצירת משימה.');
    }
  }

  // 🟢 Get tasks assigned to a specific worker (live stream)
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedTo', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // 🟢 Get tasks created by a manager
  Stream<List<TaskModel>> getTasksCreatedBy(String creatorId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: creatorId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // 🟢 Update general task status (manager only)
  Future<void> updateTaskStatus(String taskId, String status, String userId) async {
    try {
      final ref = _firestore.collection(_collection).doc(taskId);
      await ref.update({
        'status': status,
      });
    } catch (e) {
      throw CustomException('שגיאה בעדכון סטטוס המשימה.');
    }
  }

  // 🟢 Add a comment
  Future<void> addComment(String taskId, Map<String, dynamic> comment) async {
    try {
      final ref = _firestore.collection(_collection).doc(taskId);
      await ref.update({
        'comments': FieldValue.arrayUnion([comment])
      });
    } catch (e) {
      throw CustomException('שגיאה בהוספת תגובה.');
    }
  }

  // 🟢 Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collection).doc(taskId).delete();
    } catch (e) {
      throw CustomException('שגיאה במחיקת המשימה.');
    }
  }

  // 🟢 Update entire task with partial data
  Future<void> updateTask(String taskId, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection(_collection).doc(taskId).update(updatedData);
    } catch (e) {
      throw CustomException('שגיאה בעדכון המשימה.');
    }
  }

  // ✅ Update only the specific worker's entry in workerProgress
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

  // Update timestamps based on new status
  progressEntry['status'] = newStatus;
  if (newStatus == 'pending') {
    progressEntry['submittedAt'] = now;
  } else if (newStatus == 'in_progress') {
    progressEntry['startedAt'] = now;
  } else if (newStatus == 'done') {
    progressEntry['endedAt'] = now;
  }

  // Update Firestore with the user's updated progress
  await taskRef.update({'workerProgress.$userId': progressEntry});

  // Now determine global task status
  workerProgress[userId] = progressEntry;

  final allStatuses = workerProgress.values
      .map((entry) => (entry as Map<String, dynamic>)['status'] as String)
      .toList();

  String overallStatus;
  if (allStatuses.every((s) => s == 'done')) {
    overallStatus = 'done';
  } else if (allStatuses.any((s) => s == 'in_progress')) {
    overallStatus = 'in_progress';
  } else {
    overallStatus = 'pending';
  }

  // Update task global status
  await taskRef.update({'status': overallStatus});
}


  // 🟢 Get task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _firestore.collection(_collection).doc(taskId).get();
    if (doc.exists) {
      return TaskModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // ✅ Get tasks assigned to a user by selected month
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
