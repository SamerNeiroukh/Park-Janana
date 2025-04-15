import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/models/user_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/services/worker_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  final TextEditingController _commentController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<UserModel> _assignedWorkers = [];
  bool _isWorker = false;
  late TaskModel task;

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
        _assignedWorkers = workers;
        _isWorker = task.assignedTo.contains(_currentUser?.uid ?? "");
      });
    }
  }

  Future<void> _updateWorkerStatus(String newStatus) async {
    await _taskService.updateWorkerStatus(task.id, _currentUser!.uid, newStatus);
    await _fetchTaskAndWorkers();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    await _taskService.addComment(task.id, {
      'by': _currentUser!.uid,
      'message': _commentController.text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _commentController.clear();
    await _fetchTaskAndWorkers();
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'done':
        color = Colors.green;
        break;
      case 'pending':
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(_getStatusText(status)),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWorkerStatusBadge(String status) {
    Color bgColor;
    String label;
    switch (status) {
      case 'in_progress':
        bgColor = Colors.orange;
        label = 'בתהליך';
        break;
      case 'done':
        bgColor = Colors.green;
        label = 'הושלם';
        break;
      case 'pending':
      default:
        bgColor = Colors.grey;
        label = 'טרם התחיל';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bgColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return "טרם התחיל";
      case 'in_progress':
        return "בתהליך";
      case 'done':
        return "הושלם";
      default:
        return "לא ידוע";
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentWorkerStatus = task.workerStatuses[_currentUser?.uid ?? ''] ?? 'pending';

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusChip(task.status),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Text(task.title,
                          style: AppTheme.screenTitle.copyWith(fontSize: 24)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(task.description, style: AppTheme.bodyText),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("מחלקה: ${_getDepartmentName(task.department)}",
                                    style: AppTheme.bodyText),
                                Text("דחיפות: ${_getPriorityName(task.priority)}",
                                    style: AppTheme.bodyText),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "מועד סיום: ${DateFormat('dd/MM/yyyy – HH:mm').format(task.dueDate.toDate())}",
                              style: AppTheme.bodyText,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text("עובדים שהוקצו למשימה", style: AppTheme.sectionTitle),
                      const SizedBox(height: 8),
                      ..._assignedWorkers.map((user) {
                        final workerStatus = task.workerStatuses[user.uid] ?? 'pending';
                        return Card(
                          color: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user.profilePicture),
                            ),
                            title: Text(user.fullName),
                            trailing: _buildWorkerStatusBadge(workerStatus),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      Text("תגובות", style: AppTheme.sectionTitle),
                      const SizedBox(height: 8),
                      if (task.comments.isEmpty)
                        Text("אין תגובות עדיין", style: AppTheme.bodyText)
                      else
                        ...task.comments.map((comment) {
                          final message = comment['message'] ?? '';
                          final timestamp = comment['timestamp'];
                          final time = timestamp is int
                              ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                              : DateTime.now();
                          return Card(
                            elevation: 1,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const Icon(Icons.comment, color: AppColors.primary),
                              title: Text(message.toString(), textAlign: TextAlign.right),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(time),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: AppTheme.inputDecoration(hintText: "הוסף תגובה..."),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _addComment,
                        style: AppTheme.primaryButtonStyle,
                        child: const Text("💬 שלח תגובה"),
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

  String _getPriorityName(String key) {
    switch (key) {
      case 'high':
        return 'גבוהה';
      case 'low':
        return 'נמוכה';
      default:
        return 'בינונית';
    }
  }

  String _getDepartmentName(String key) {
    switch (key) {
      case 'paintball':
        return 'פיינטבול';
      case 'ropes':
        return 'פארק חבלים';
      case 'carting':
        return 'קארטינג';
      case 'water_park':
        return 'פארק מים';
      case 'jimbory':
        return 'גִימבורי';
      default:
        return 'כללי';
    }
  }
}
