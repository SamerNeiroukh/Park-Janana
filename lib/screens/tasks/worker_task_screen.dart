import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../widgets/user_header.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_colors.dart';

class WorkerTaskScreen extends StatefulWidget {
  const WorkerTaskScreen({super.key});

  @override
  State<WorkerTaskScreen> createState() => _WorkerTaskScreenState();
}

class _WorkerTaskScreenState extends State<WorkerTaskScreen> {
  final TaskService _taskService = TaskService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const UserHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text("המשימות שלי", style: AppTheme.screenTitle),
          ),
          _buildStatusFilterButtons(),
          Expanded(
            child: _currentUser == null
                ? const Center(child: Text("שגיאה בזיהוי המשתמש."))
                : StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getTasksForUser(_currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.task_alt, size: 60, color: AppColors.textSecondary),
                              const SizedBox(height: 10),
                              Text("אין משימות פעילות כרגע.", style: AppTheme.bodyText),
                            ],
                          ),
                        );
                      }

                      List<TaskModel> tasks = snapshot.data!;
                      if (_selectedStatus != 'all') {
                        tasks = tasks.where((t) => t.status == _selectedStatus).toList();
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: tasks.map((task) => _buildTaskCard(task)).toList(),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusFilterButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFilterButton('all', 'הכל', Colors.grey),
          _buildFilterButton('pending', 'ממתין', Colors.red),
          _buildFilterButton('in_progress', 'בתהליך', Colors.orange),
          _buildFilterButton('done', 'הושלם', Colors.green),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String status, String label, Color color) {
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color : color.withOpacity(0.2),
          foregroundColor: isSelected ? Colors.white : color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          minimumSize: const Size(80, 40),
        ),
        onPressed: () => setState(() => _selectedStatus = status),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              overflow: TextOverflow.ellipsis,
            ),
            softWrap: false,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(task.title, style: AppTheme.sectionTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 6),
            Text(task.description, style: AppTheme.bodyText.copyWith(fontSize: 14)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "⏰ עד: ${_formatTimestamp(task.dueDate)}",
                  style: AppTheme.bodyText.copyWith(color: AppColors.textSecondary),
                ),
                _buildStatusChip(task.status),
              ],
            ),
            if (task.status != 'done') _buildActionButtons(task),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;
    switch (status) {
      case 'in_progress':
        color = Colors.orange;
        label = 'בתהליך';
        break;
      case 'done':
        color = Colors.green;
        label = 'הושלם';
        break;
      default:
        color = Colors.red;
        label = 'ממתין';
    }
    return Chip(
      backgroundColor: color,
      label: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildActionButtons(TaskModel task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () => _updateStatus(task, 'in_progress'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          child: const Text("התחל"),
        ),
        ElevatedButton(
          onPressed: () => _updateStatus(task, 'done'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text("סיום"),
        ),
      ],
    );
  }

  // ✅ FIXED: Now calls updateWorkerStatus instead of updateTaskStatus
  Future<void> _updateStatus(TaskModel task, String status) async {
    if (_currentUser == null) return;
    await _taskService.updateWorkerStatus(task.id, _currentUser!.uid, status);
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}
