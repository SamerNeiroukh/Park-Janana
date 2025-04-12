import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/models/user_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/services/worker_service.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/widgets/task_card.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'create_task_screen.dart';

class ManagerTasksScreen extends StatefulWidget {
  const ManagerTasksScreen({super.key});

  @override
  State<ManagerTasksScreen> createState() => _ManagerTasksScreenState();
}

class _ManagerTasksScreenState extends State<ManagerTasksScreen> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  String? _selectedWorkerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserHeader(), // ✅ Consistent User Header
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 📌 **Worker Filter Dropdown**
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: StreamBuilder<List<UserModel>>(
              stream: _workerService.getAllWorkersStream(), // ✅ Real-time updates
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<UserModel> workers = snapshot.data!;
                return DropdownButtonFormField<String>(
                  value: _selectedWorkerId,
                  decoration: AppTheme.inputDecoration(hintText: "בחר עובד"),
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedWorkerId = newValue;
                    });
                  },
                  items: [
                    const DropdownMenuItem(value: null, child: Text("כל העובדים")),
                    ...workers.map((worker) => DropdownMenuItem(
                          value: worker.uid,
                          child: Text(worker.fullName, textAlign: TextAlign.right),
                        )),
                  ],
                );
              },
            ),
          ),

          // 📌 **Task List with Firestore Stream**
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: _taskService.getAllTasksStream(), // ✅ Real-time Firestore updates
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("אין משימות זמינות.", style: AppTheme.bodyText),
                  );
                }

                List<TaskModel> tasks = _selectedWorkerId == null
                    ? snapshot.data!
                    : snapshot.data!.where((task) => task.assignedWorkerId == _selectedWorkerId).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    TaskModel task = tasks[index];
                    return TaskCard(
                      task: task,
                      taskService: _taskService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_task, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
          );
        },
      ),
    );
  }
}
