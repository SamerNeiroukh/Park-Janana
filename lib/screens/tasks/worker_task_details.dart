import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/services/worker_service.dart';
import 'package:park_janana/widgets/task/task_description_section.dart';
import 'package:park_janana/widgets/task/task_comments_section.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/utils/alert_service.dart';

class WorkerTaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const WorkerTaskDetailsScreen({super.key, required this.task});

  @override
  State<WorkerTaskDetailsScreen> createState() => _WorkerTaskDetailsScreenState();
}

class _WorkerTaskDetailsScreenState extends State<WorkerTaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  final TextEditingController _commentController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  bool _isWorker = false;
  late TaskModel task;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    _fetchTaskAndWorkers();
  }

  Future<void> _fetchTaskAndWorkers() async {
    final updatedTask = await _taskService.getTaskById(widget.task.id);
    if (updatedTask != null) {
      final workers = await _workerService.getUsersByIds(updatedTask.assignedTo);
      setState(() {
        task = updatedTask;
        _isWorker = task.assignedTo.contains(_currentUser?.uid ?? "");
      });
    }
  }

  Future<void> _updateWorkerStatus(String newStatus) async {
    await _taskService.updateWorkerStatus(task.id, _currentUser!.uid, newStatus);
    await _fetchTaskAndWorkers();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      await _taskService.addComment(task.id, {
        'by': _currentUser!.uid,
        'message': _commentController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentController.clear();
      await _fetchTaskAndWorkers();
    } catch (e) {
      debugPrint("Failed to submit comment: $e");
      AlertService.error(context, "שגיאה בשליחת תגובה");
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _currentUser?.uid ?? '';
    final currentWorkerStatus = task.workerProgress[userId]?['status'] ?? 'pending';

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
                        dateFormatted:
                            DateFormat('dd/MM/yyyy').format(task.dueDate.toDate()),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text("🚧 התחל משימה"),
                        ),
                      if (_isWorker && currentWorkerStatus == 'in_progress')
                        ElevatedButton(
                          onPressed: () => _updateWorkerStatus('done'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
