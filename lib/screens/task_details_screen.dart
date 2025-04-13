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
    _fetchAssignedUsers();
  }

  Future<void> _fetchAssignedUsers() async {
    final workers = await _workerService.getUsersByIds(task.assignedTo);
    setState(() {
      _assignedWorkers = workers;
      _isWorker = task.assignedTo.contains(_currentUser?.uid ?? "");
    });
  }

  Future<void> _updateStatus(String status) async {
    await _taskService.updateTaskStatus(task.id, status, _currentUser!.uid);
    setState(() {
      task = TaskModel(
        id: task.id,
        title: task.title,
        description: task.description,
        department: task.department,
        createdBy: task.createdBy,
        assignedTo: task.assignedTo,
        dueDate: task.dueDate,
        priority: task.priority,
        status: status,
        attachments: task.attachments,
        comments: task.comments,
        createdAt: task.createdAt,
      );
    });
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty) return;
    await _taskService.addComment(task.id, {
      'by': _currentUser!.uid,
      'message': _commentController.text,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    _commentController.clear();
    setState(() {}); // trigger UI refresh
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.grey;
        break;
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'done':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(_getStatusText(status)),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const UserHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(task.title, style: AppTheme.screenTitle),
                    const SizedBox(height: 8),
                    _buildStatusChip(task.status),
                    const SizedBox(height: 16),
                    Text(task.description, style: AppTheme.bodyText),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("מחלקה: ${task.department}", style: AppTheme.bodyText),
                        Text("דחיפות: ${task.priority}", style: AppTheme.bodyText),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "מועד סיום: ${DateFormat('dd/MM/yyyy – HH:mm').format(task.dueDate.toDate())}",
                      style: AppTheme.bodyText,
                    ),
                    const Divider(height: 32),
                    Text("עובדים שהוקצו למשימה:", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    ..._assignedWorkers.map((user) => ListTile(
                          title: Text(user.fullName, textAlign: TextAlign.right),
                          leading: CircleAvatar(backgroundImage: NetworkImage(user.profilePicture)),
                        )),
                    const Divider(height: 32),
                    Text("תגובות:", style: AppTheme.sectionTitle),
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
                        return ListTile(
                          title: Text(message.toString(), textAlign: TextAlign.right),
                          subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(time)),
                          trailing: const Icon(Icons.comment),
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
                      child: const Text("💬 שלח תגובה"),
                    ),
                    const Divider(height: 32),
                    if (_isWorker && task.status == 'pending')
                      ElevatedButton(
                        onPressed: () => _updateStatus('in_progress'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        child: const Text("🚧 התחל משימה"),
                      ),
                    if (_isWorker && task.status == 'in_progress')
                      ElevatedButton(
                        onPressed: () => _updateStatus('done'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text("✅ סיים משימה"),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
