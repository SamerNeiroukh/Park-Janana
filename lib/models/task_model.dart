import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { notStarted, inProgress, completed }
enum TaskPriority { low, medium, high }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedWorkerId;
  final DateTime deadline;
  final TaskStatus status;
  final TaskPriority priority;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedWorkerId,
    required this.deadline,
    required this.status,
    required this.priority,
  });

  // ✅ Convert Firestore data to `TaskModel`
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedWorkerId: map['assignedWorkerId'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(), // Convert Firestore Timestamp to DateTime
      status: _convertToTaskStatus(map['status']),
      priority: _convertToTaskPriority(map['priority']),
    );
  }

  // ✅ Convert `TaskModel` to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedWorkerId': assignedWorkerId,
      'deadline': Timestamp.fromDate(deadline), // Convert DateTime to Firestore Timestamp
      'status': status.name, // Convert Enum to String
      'priority': priority.name, // Convert Enum to String
    };
  }

  // 🔹 Safe conversion for TaskStatus
  static TaskStatus _convertToTaskStatus(String? value) {
    try {
      return TaskStatus.values.byName(value ?? 'notStarted');
    } catch (e) {
      return TaskStatus.notStarted; // Default value in case of an error
    }
  }

  // 🔹 Safe conversion for TaskPriority
  static TaskPriority _convertToTaskPriority(String? value) {
    try {
      return TaskPriority.values.byName(value ?? 'medium');
    } catch (e) {
      return TaskPriority.medium; // Default value in case of an error
    }
  }
}
