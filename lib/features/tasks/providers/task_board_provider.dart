import 'dart:async';
import 'package:flutter/material.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';

/// Manages state for the Manager Kanban Board screen.
class TaskBoardProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();

  StreamSubscription? _subscription;
  List<TaskModel> _allTasks = [];
  final Map<String, UserModel> _workerCache = {};

  String _searchQuery = '';
  String? _departmentFilter;
  bool _isLoading = true;

  // Getters
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get departmentFilter => _departmentFilter;
  Map<String, UserModel> get workerCache => _workerCache;

  List<TaskModel> get _filteredTasks {
    var tasks = _allTasks;

    if (_departmentFilter != null) {
      tasks = tasks.where((t) => t.department == _departmentFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      tasks = tasks.where((t) =>
          t.title.toLowerCase().contains(q) ||
          t.description.toLowerCase().contains(q)).toList();
    }

    return tasks;
  }

  List<TaskModel> get pendingTasks =>
      _filteredTasks.where((t) => t.status == 'pending').toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<TaskModel> get inProgressTasks =>
      _filteredTasks.where((t) => t.status == 'in_progress').toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

  List<TaskModel> get doneTasks =>
      _filteredTasks.where((t) => t.status == 'done').toList()
        ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

  int get totalCount => _filteredTasks.length;
  int get overdueCount => _filteredTasks.where((t) => t.isOverdue).length;

  void init(String managerId) {
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _taskService.getTasksCreatedBy(managerId).listen(
      (tasks) async {
        _allTasks = tasks;
        await _fetchWorkers(tasks);
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('TaskBoardProvider stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _fetchWorkers(List<TaskModel> tasks) async {
    final ids = tasks.expand((t) => t.assignedTo).toSet().toList();
    final newIds = ids.where((id) => !_workerCache.containsKey(id)).toList();
    if (newIds.isEmpty) return;

    try {
      final users = await _workerService.getUsersByIds(newIds);
      for (final u in users) {
        _workerCache[u.uid] = u;
      }
    } catch (e) {
      debugPrint('Failed to fetch workers: $e');
    }
  }

  List<UserModel> workersForTask(TaskModel task) {
    return task.assignedTo
        .where((id) => _workerCache.containsKey(id))
        .map((id) => _workerCache[id]!)
        .toList();
  }

  void setSearch(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setDepartmentFilter(String? department) {
    _departmentFilter = department;
    notifyListeners();
  }

  /// Returns true when at least one worker on [task] is awaiting review.
  bool hasPendingReview(TaskModel task) {
    return task.workerProgress.values
        .any((p) => (p['status'] as String?) == 'pending_review');
  }

  /// Returns the IDs of workers whose status is [pending_review] for [task].
  List<String> pendingReviewWorkers(TaskModel task) {
    return task.workerProgress.entries
        .where((e) => (e.value['status'] as String?) == 'pending_review')
        .map((e) => e.key)
        .toList();
  }

  Future<void> approveWorker(
      String taskId, String workerId, String managerId) async {
    await _taskService.approveWorkerTask(taskId, workerId, managerId);
  }

  Future<void> deleteTask(String taskId) async {
    await _taskService.deleteTask(taskId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
