import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/features/tasks/widgets/task_description_section.dart';
import 'package:park_janana/features/tasks/widgets/task_comments_section.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class WorkerTaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const WorkerTaskDetailsScreen({super.key, required this.task});

  @override
  State<WorkerTaskDetailsScreen> createState() =>
      _WorkerTaskDetailsScreenState();
}

class _WorkerTaskDetailsScreenState extends State<WorkerTaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  final TextEditingController _commentController = TextEditingController();

  bool _isWorker = false;
  late TaskModel task;
  bool _isSubmitting = false;

  String? get _currentUid => context.read<AppAuthProvider>().uid;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    _fetchTaskAndWorkers();
  }

  Future<void> _fetchTaskAndWorkers() async {
    final updatedTask = await _taskService.getTaskById(widget.task.id);
    if (updatedTask != null) {
      final workers =
          await _workerService.getUsersByIds(updatedTask.assignedTo);
      setState(() {
        task = updatedTask;
        _isWorker = task.assignedTo.contains(_currentUid ?? "");
      });
    }
  }

  Future<void> _updateWorkerStatus(String newStatus) async {
    if (_currentUid == null) return;
    await _taskService.updateWorkerStatus(task.id, _currentUid!, newStatus);
    await _fetchTaskAndWorkers();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _isSubmitting || _currentUid == null)
      return;

    setState(() => _isSubmitting = true);

    try {
      await _taskService.addComment(task.id, {
        'by': _currentUid,
        'message': _commentController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentController.clear();
      await _fetchTaskAndWorkers();
    } catch (e) {
      debugPrint("Failed to submit comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("שגיאה בשליחת תגובה")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _currentUid ?? '';
    final currentWorkerStatus =
        task.workerProgress[userId]?['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const UserHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchTaskAndWorkers,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(task.title,
                          style: AppTheme.screenTitle.copyWith(fontSize: 24)),
                      const SizedBox(height: 16),
                      TaskDescriptionSection(
                        description: task.description,
                        time: DateFormat('HH:mm').format(task.dueDate.toDate()),
                        dateFormatted: DateFormat('dd/MM/yyyy')
                            .format(task.dueDate.toDate()),
                        isManager: false,
                        task: task,
                      ),
                      const SizedBox(height: 24),
                      TaskCommentsSection(
                        comments: task.comments,
                        taskId: task.id,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration:
                            AppTheme.inputDecoration(hintText: "הוסף תגובה..."),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _addComment,
                        style: AppTheme.primaryButtonStyle,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("💬 שלח תגובה"),
                      ),
                      const SizedBox(height: 32),
                      if (_isWorker && currentWorkerStatus == 'pending')
                        ElevatedButton(
                          onPressed: () => _updateWorkerStatus('in_progress'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text("🚧 התחל משימה"),
                        ),
                      if (_isWorker && currentWorkerStatus == 'in_progress')
                        ElevatedButton(
                          onPressed: () => _updateWorkerStatus('done'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text("✅ סיים משימה"),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
