import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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
  final Timestamp? updatedAt;
  final List<Map<String, dynamic>> activityLog;

  /// Per-worker progress with dates and status
  final Map<String, Map<String, dynamic>> workerProgress;

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
    required this.workerProgress,
    this.updatedAt,
    this.activityLog = const [],
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
      workerProgress: _parseWorkerProgress(data['workerProgress']),
      updatedAt: data['updatedAt'] as Timestamp?,
      activityLog: List<Map<String, dynamic>>.from(data['activityLog'] ?? []),
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
      workerProgress: _parseWorkerProgress(data['workerProgress']),
      updatedAt: data['updatedAt'] as Timestamp?,
      activityLog: List<Map<String, dynamic>>.from(data['activityLog'] ?? []),
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
      'workerProgress': workerProgress,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'activityLog': activityLog,
    };
  }

  static Map<String, Map<String, dynamic>> _parseWorkerProgress(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) => MapEntry(
        key,
        Map<String, dynamic>.from(value as Map),
      ));
    }
    return {};
  }

  // Helpers
  bool get isOverdue =>
      status != 'done' && dueDate.toDate().isBefore(DateTime.now());

  bool get isDueToday {
    final now = DateTime.now();
    final due = dueDate.toDate();
    return due.year == now.year &&
        due.month == now.month &&
        due.day == now.day;
  }

  bool get isUpcoming =>
      status != 'done' && dueDate.toDate().isAfter(DateTime.now()) && !isDueToday;

  double get completionRatio {
    if (workerProgress.isEmpty) return 0;
    final done = workerProgress.values
        .where((p) => p['status'] == 'done')
        .length;
    return done / workerProgress.length;
  }

  int get completedWorkerCount =>
      workerProgress.values.where((p) => p['status'] == 'done').length;

  int get totalWorkerCount => workerProgress.length;

  String workerStatusFor(String userId) =>
      workerProgress[userId]?['status'] as String? ?? 'pending';

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? department,
    String? createdBy,
    List<String>? assignedTo,
    Timestamp? dueDate,
    String? priority,
    String? status,
    List<String>? attachments,
    List<Map<String, dynamic>>? comments,
    Timestamp? createdAt,
    Map<String, Map<String, dynamic>>? workerProgress,
    Timestamp? updatedAt,
    List<Map<String, dynamic>>? activityLog,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      department: department ?? this.department,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      attachments: attachments ?? this.attachments,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      workerProgress: workerProgress ?? this.workerProgress,
      updatedAt: updatedAt ?? this.updatedAt,
      activityLog: activityLog ?? this.activityLog,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, priority: $priority, workers: ${workerProgress.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TaskModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.department == department &&
        other.createdBy == createdBy &&
        listEquals(other.assignedTo, assignedTo) &&
        other.dueDate == dueDate &&
        other.priority == priority &&
        other.status == status &&
        listEquals(other.attachments, attachments) &&
        _listOfMapsEquals(other.comments, comments) &&
        other.createdAt == createdAt &&
        _mapOfMapsEquals(other.workerProgress, workerProgress);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        department.hashCode ^
        createdBy.hashCode ^
        assignedTo.hashCode ^
        dueDate.hashCode ^
        priority.hashCode ^
        status.hashCode ^
        attachments.hashCode ^
        comments.hashCode ^
        createdAt.hashCode ^
        workerProgress.hashCode;
  }

  static bool _listOfMapsEquals(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!mapEquals(a[i], b[i])) return false;
    }
    return true;
  }

  static bool _mapOfMapsEquals(
      Map<String, Map<String, dynamic>> a, Map<String, Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!mapEquals(a[key], b[key])) return false;
    }
    return true;
  }
}
