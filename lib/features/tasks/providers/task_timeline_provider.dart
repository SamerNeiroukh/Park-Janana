import 'dart:async';
import 'package:flutter/material.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';

/// Manages state for the Worker Timeline screen.
/// Auto-categorizes tasks into overdue/today/upcoming/completed sections.
class TaskTimelineProvider extends ChangeNotifier {
  final TaskService _taskService = TaskService();

  StreamSubscription? _subscription;
  List<TaskModel> _allTasks = [];
  bool _isLoading = true;
  String? _userId;

  bool get isLoading => _isLoading;

  // pending_review is treated as active (worker is waiting for manager approval)
  bool _isActive(TaskModel t) => _workerStatus(t) != 'done';

  List<TaskModel> get overdueTasks {
    return _allTasks
        .where((t) => _isActive(t) && _isPastDue(t))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<TaskModel> get todayTasks {
    return _allTasks
        .where((t) => _isActive(t) && t.isDueToday && !_isPastDue(t))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<TaskModel> get upcomingTasks {
    return _allTasks
        .where((t) => _isActive(t) && t.isUpcoming)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<TaskModel> get completedTasks {
    return _allTasks
        .where((t) => _workerStatus(t) == 'done')
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  }

  int get todayTotal {
    final now = DateTime.now();
    return _allTasks.where((t) {
      final d = t.dueDate.toDate();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
  }

  int get todayCompleted {
    final now = DateTime.now();
    return _allTasks.where((t) {
      final d = t.dueDate.toDate();
      return d.year == now.year &&
          d.month == now.month &&
          d.day == now.day &&
          _workerStatus(t) == 'done';
    }).length;
  }

  double get todayProgress =>
      todayTotal == 0 ? 0 : todayCompleted / todayTotal;

  void init(String userId) {
    _userId = userId;
    _subscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _subscription = _taskService.getTasksForUser(userId).listen(
      (tasks) {
        _allTasks = tasks;
        _isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('TaskTimelineProvider stream error: $e');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  String _workerStatus(TaskModel task) {
    if (_userId == null) return 'pending';
    return task.workerStatusFor(_userId!);
  }

  bool _isPastDue(TaskModel task) {
    return task.dueDate.toDate().isBefore(DateTime.now()) && !task.isDueToday;
  }

  Future<void> updateStatus(String taskId, String newStatus) async {
    if (_userId == null) return;
    await _taskService.updateWorkerStatus(taskId, _userId!, newStatus);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
