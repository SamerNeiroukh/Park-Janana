import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/widgets/user_header.dart';

class WorkerTasksScreen extends StatefulWidget {
  const WorkerTasksScreen({super.key});

  @override
  State<WorkerTasksScreen> createState() => _WorkerTasksScreenState();
}

class _WorkerTasksScreenState extends State<WorkerTasksScreen> {
  final TaskService _taskService = TaskService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserHeader(), // ✅ Consistent User Header
      backgroundColor: AppColors.background,
      body: _currentUser == null
          ? const Center(child: Text("שגיאה בטעינת הנתונים"))
          : StreamBuilder<List<TaskModel>>(
              stream: _taskService.getTasksForWorker(_currentUser!.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("אין משימות זמינות כרגע.",
                          style: AppTheme.bodyText));
                }

                List<TaskModel> tasks = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    TaskModel task = tasks[index];
                    return _buildTaskCard(task);
                  },
                );
              },
            ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      color: task.status == TaskStatus.completed
          ? Colors.green.shade100
          : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // ✅ Align Right-to-Left
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(task.title,
                      style: AppTheme.sectionTitle,
                      textAlign: TextAlign.right),
                ),
                task.status == TaskStatus.completed
                    ? const Icon(Icons.check_circle,
                        color: Colors.green, size: 28)
                    : IconButton(
                        icon: const Icon(Icons.done, color: Colors.blue, size: 28),
                        onPressed: () => _markTaskAsCompleted(task),
                      ),
              ],
            ),
            const SizedBox(height: 6),
            Text("🗂 ${task.description}",
                style: AppTheme.bodyText, textAlign: TextAlign.right),
            const SizedBox(height: 6),
            Text("📅 ${DateFormat('dd/MM/yyyy').format(task.deadline)}",
                style: AppTheme.bodyText, textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }

  void _markTaskAsCompleted(TaskModel task) async {
    await _taskService.updateTaskStatus(task.id, TaskStatus.completed); // ✅ Fixed Enum Usage
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ המשימה סומנה כהושלמה!")),
      );
    }
  }
}
