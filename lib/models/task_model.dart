import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String department;
  final String createdBy;
  final List<String> assignedTo;
  final Timestamp dueDate;
  final String priority;
  final String status;
  final List<String> attachments;
  final List<Map<String, dynamic>> comments;
  final Timestamp createdAt;
  final Map<String, String> workerStatuses;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.department,
    required this.createdBy,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.attachments,
    required this.comments,
    required this.createdAt,
    required this.workerStatuses,
  });

  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      department: data['department'] ?? '',
      createdBy: data['createdBy'] ?? '',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      dueDate: data['dueDate'],
      priority: data['priority'] ?? 'low',
      status: data['status'] ?? 'pending',
      attachments: List<String>.from(data['attachments'] ?? []),
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
      createdAt: data['createdAt'],
      workerStatuses: _parseWorkerStatuses(data['workerStatuses']),
    );
  }

  factory TaskModel.fromMap(String id, Map<String, dynamic> data) {
    return TaskModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      department: data['department'] ?? '',
      createdBy: data['createdBy'] ?? '',
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
      dueDate: data['dueDate'],
      priority: data['priority'] ?? 'low',
      status: data['status'] ?? 'pending',
      attachments: List<String>.from(data['attachments'] ?? []),
      comments: List<Map<String, dynamic>>.from(data['comments'] ?? []),
      createdAt: data['createdAt'],
      workerStatuses: _parseWorkerStatuses(data['workerStatuses']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'department': department,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'dueDate': dueDate,
      'priority': priority,
      'status': status,
      'attachments': attachments,
      'comments': comments,
      'createdAt': createdAt,
      'workerStatuses': workerStatuses,
    };
  }

  static Map<String, String> _parseWorkerStatuses(dynamic raw) {
    if (raw is Map) {
      return Map<String, String>.fromEntries(
        raw.entries.map((e) => MapEntry(e.key.toString(), e.value.toString())),
      );
    }
    return {};
  }
}
