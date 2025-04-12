import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final TaskService taskService;

  const TaskCard({
    super.key,
    required this.task,
    required this.taskService, // ✅ Fixed missing argument
  });

  void _markTaskAsCompleted(BuildContext context) async {
    await taskService.updateTaskStatus(task.id, TaskStatus.completed); // ✅ Fixed type error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🎉 המשימה הושלמה!"),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = task.status == TaskStatus.completed;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isCompleted ? AppColors.success.withOpacity(0.2) : Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCompleted ? AppColors.success : AppColors.primary,
          child: Icon(
            isCompleted ? Icons.check : Icons.assignment,
            color: Colors.white,
          ),
        ),
        title: Text(
          task.title,
          style: AppTheme.bodyText.copyWith(
            fontWeight: FontWeight.bold,
            color: isCompleted ? AppColors.success : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          "מועד אחרון: ${DateFormat('dd/MM/yyyy').format(task.deadline)}",
          style: AppTheme.bodyText.copyWith(color: AppColors.textSecondary),
        ),
        trailing: isCompleted
            ? const Icon(Icons.check_circle, color: AppColors.success)
            : IconButton(
                icon: const Icon(Icons.check, color: AppColors.primary),
                onPressed: () => _markTaskAsCompleted(context),
              ),
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => _taskDetailsDialog(context),
          );
        },
      ),
    );
  }

  Widget _taskDetailsDialog(BuildContext context) {
    return AlertDialog(
      title: Text("פרטי משימה", style: AppTheme.sectionTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text("📝 ${task.description}", style: AppTheme.bodyText),
          const SizedBox(height: 10),
          Text(
            "📅 מועד אחרון: ${DateFormat('dd/MM/yyyy').format(task.deadline)}",
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("סגור"),
        ),
      ],
    );
  }
}
