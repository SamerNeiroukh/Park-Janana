import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import '../constants/app_constants.dart';
import '../utils/custom_exception.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'tasks';

  // 🟢 Create a new task
  Future<void> createTask(TaskModel task) async {
    try {
      await _firestore.collection(_collection).doc(task.id).set(task.toMap());
    } catch (e) {
      throw CustomException('שגיאה ביצירת משימה.');
    }
  }

  // 🟢 Get tasks assigned to a specific worker
  Stream<List<TaskModel>> getTasksForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('assignedTo', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // 🟢 Get tasks created by a manager (fixed: removed orderBy to prevent disappearing)
  Stream<List<TaskModel>> getTasksCreatedBy(String creatorId) {
    return _firestore
        .collection(_collection)
        .where('createdBy', isEqualTo: creatorId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // 🟢 Update task status and log comment
  Future<void> updateTaskStatus(String taskId, String status, String userId) async {
    try {
      final ref = _firestore.collection(_collection).doc(taskId);
      await ref.update({
        'status': status,
        'comments': FieldValue.arrayUnion([
          {
            'by': userId,
            'status': status,
            'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
          }
        ])
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

  Future<void> updateTask(String taskId, Map<String, dynamic> updatedData) async {
  try {
    await _firestore.collection(_collection).doc(taskId).update(updatedData);
  } catch (e) {
    throw CustomException('שגיאה בעדכון המשימה.');
  }
}
}
