import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';
import 'package:flutter/foundation.dart'; // ✅ For debugPrint()

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Create a new task
  Future<void> createTask(TaskModel task) async {
    await _firestore.collection('tasks').doc(task.id).set(task.toMap()); // ✅ Fixed
  }

  // 🔹 Fetch all tasks assigned to a specific worker (Stream for live updates)
  Stream<List<TaskModel>> getTasksForWorker(String workerId) {
    return _firestore
        .collection('tasks')
        .where('assignedWorkerId', isEqualTo: workerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromMap(doc.data())).toList()); // ✅ Fixed
  }

  // 🔹 Fetch all tasks assigned to a specific worker (Future for one-time fetch)
  Future<List<TaskModel>> fetchTasksForWorker(String workerId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('tasks')
        .where('assignedWorkerId', isEqualTo: workerId)
        .get();

    return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>)).toList(); // ✅ Fixed
  }

  // 🔹 Fetch all tasks for managers (Stream for real-time updates)
  Stream<List<TaskModel>> getAllTasksStream() {
    return _firestore.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromMap(doc.data())).toList()); // ✅ Fixed
  }

  // 🔹 Fetch all tasks for managers (Future for static data)
  Future<List<TaskModel>> fetchAllTasks() async {
    QuerySnapshot snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs.map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>)).toList(); // ✅ Fixed
  }

  // 🔹 Update task status (Now accepts TaskStatus instead of String)
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': status.name, // ✅ Store status as String for Firebase compatibility
    });
  }

  // 🔹 Add a worker comment to a task (Includes formatted timestamp)
  Future<void> addComment(String taskId, String workerId, String comment) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'comments': FieldValue.arrayUnion([
        {
          'workerId': workerId,
          'comment': comment,
          'timestamp': Timestamp.now(), // ✅ Ensuring timestamp for sorting
        }
      ])
    });
  }

  // 🔹 Delete a task (Safeguard added)
  Future<void> deleteTask(String taskId) async {
    DocumentSnapshot taskDoc = await _firestore.collection('tasks').doc(taskId).get();
    if (taskDoc.exists) {
      await _firestore.collection('tasks').doc(taskId).delete();
    } else {
      debugPrint("❌ Task does not exist!"); // ✅ Replaced print() with debugPrint()
    }
  }
}
