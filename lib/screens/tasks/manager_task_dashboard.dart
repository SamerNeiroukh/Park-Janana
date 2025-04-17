// unchanged import statements
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import 'task_details_screen.dart';
import '../../screens/tasks/create_task_screen.dart';
import '../../screens/tasks/edit_task_screen.dart';
import '../../services/task_service.dart';
import '../../services/worker_service.dart';
import '../../widgets/user_header.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_colors.dart';
import 'package:intl/intl.dart';

class ManagerTaskDashboard extends StatefulWidget {
  const ManagerTaskDashboard({super.key});

  @override
  State<ManagerTaskDashboard> createState() => _ManagerTaskDashboardState();
}

class _ManagerTaskDashboardState extends State<ManagerTaskDashboard> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  String selectedStatus = 'all';
  DateTime selectedDate = DateTime.now();

  bool _isNavigating = false; // ✅ prevent multiple FAB presses

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _handleCreateTaskPress,
        label: const Text("יצירת משימה", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          const UserHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text("ניהול משימות", style: AppTheme.screenTitle),
          ),
          _buildDateNavigation(),
          _buildFilterButtons(),
          Expanded(
            child: _currentUser == null
                ? const Center(child: Text("שגיאה בזיהוי המשתמש."))
                : StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getTasksCreatedBy(_currentUser!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("אין משימות פעילות."));
                      }

                      List<TaskModel> tasks = snapshot.data!;

                      tasks = tasks.where((t) {
                        final tDate = t.dueDate.toDate();
                        return tDate.year == selectedDate.year &&
                            tDate.month == selectedDate.month &&
                            tDate.day == selectedDate.day;
                      }).toList();

                      if (selectedStatus != 'all') {
                        tasks = tasks.where((t) => t.status == selectedStatus).toList();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  void _handleCreateTaskPress() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
    );

    if (mounted) {
      setState(() => _isNavigating = false);
    }
  }

  Widget _buildDateNavigation() {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate);

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 30),
            onPressed: () => _changeDate(-1),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: const Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 30),
            onPressed: () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale("he", "IL"),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildFilterButtons() {
    final List<Map<String, dynamic>> buttonData = [
      {'label': 'הכל', 'value': 'all', 'color': Colors.grey},
      {'label': 'ממתין', 'value': 'pending', 'color': Colors.red},
      {'label': 'בתהליך', 'value': 'in_progress', 'color': Colors.orange},
      {'label': 'הושלם', 'value': 'done', 'color': Colors.green},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: buttonData.map((data) {
          final String value = data['value'];
          final String label = data['label'];
          final Color color = data['color'];
          final bool isSelected = selectedStatus == value;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () => setState(() => selectedStatus = value),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? color : color.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: isSelected ? 4 : 0,
                ),
                child: FittedBox(
                  child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final DateTime date = task.dueDate.toDate();
    final String time = DateFormat('HH:mm').format(date);
    final String dateFormatted = DateFormat('dd/MM/yyyy').format(date);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusChip(task.status),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
                      );
                    } else if (value == 'delete') {
                      _confirmDeleteTask(task);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text("✏️ ערוך")),
                    const PopupMenuItem(value: 'delete', child: Text("🗑️ מחק")),
                  ],
                )
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<List<UserModel>>(
                  future: _workerService.getUsersByIds(task.assignedTo),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                    return Row(
                      children: snapshot.data!.take(3).map((user) {
                        return Container(
                          margin: const EdgeInsets.only(left: 6),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: user.profilePicture.isNotEmpty
                                ? NetworkImage(user.profilePicture)
                                : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                Text(
                  dateFormatted,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            )
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
      backgroundColor: color.withOpacity(0.15),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _confirmDeleteTask(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("אישור מחיקה"),
        content: Text("האם אתה בטוח שברצונך למחוק את המשימה '${task.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ביטול"),
          ),
          TextButton(
            onPressed: () async {
              await _taskService.deleteTask(task.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("מחק", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
