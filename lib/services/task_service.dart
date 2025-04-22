import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
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

  // ✅ Update worker-specific status inside the task
  Future<void> updateWorkerStatus(String taskId, String userId, String newStatus) async {
    final taskRef = _firestore.collection(_collection).doc(taskId);
    final snapshot = await taskRef.get();

    if (!snapshot.exists) {
      print('❌ Task not found: $taskId');
      return;
    }

    final data = snapshot.data()!;
    final workerStatusesRaw = data['workerStatuses'];
    final Map<String, dynamic> workerStatuses = workerStatusesRaw is Map<String, dynamic>
        ? Map<String, dynamic>.from(workerStatusesRaw)
        : {};

    print('✅ [Before] workerStatuses: $workerStatuses');
    print('👤 Updating status for $userId → $newStatus');

    workerStatuses[userId] = newStatus;

    // Aggregate overall task status
    String updatedStatus = data['status'];
    final values = workerStatuses.values.map((v) => v.toString()).toList();

    if (values.contains('in_progress')) {
      updatedStatus = 'in_progress';
    }
    if (values.isNotEmpty && values.every((status) => status == 'done')) {
      updatedStatus = 'done';
    }

    await taskRef.update({
      'workerStatuses': workerStatuses,
      'status': updatedStatus,
    });

    print('✅ [After] workerStatuses: $workerStatuses');
    print('📦 Firestore task updated successfully.');
  }

  // 🟢 Get task by ID
  Future<TaskModel?> getTaskById(String taskId) async {
    final doc = await _firestore.collection(_collection).doc(taskId).get();
    if (doc.exists) {
      return TaskModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }
}
