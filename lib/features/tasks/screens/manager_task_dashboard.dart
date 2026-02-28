// unchanged import statements
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'task_details_screen.dart';
import 'package:park_janana/features/tasks/screens/create_task_screen.dart';
import 'package:park_janana/features/tasks/screens/edit_task_screen.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/widgets/shimmer_loading.dart';

class ManagerTaskDashboard extends StatefulWidget {
  const ManagerTaskDashboard({super.key});

  @override
  State<ManagerTaskDashboard> createState() => _ManagerTaskDashboardState();
}

class _ManagerTaskDashboardState extends State<ManagerTaskDashboard> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();

  String selectedStatus = 'all';
  DateTime selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool _isNavigating = false; // ✅ prevent multiple FAB presses

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentUid = authProvider.uid;

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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Text("ניהול משימות", style: AppTheme.screenTitle),
          ),
          _buildDateNavigation(),
          _buildFilterButtons(),
          _buildSearchBar(),
          Expanded(
            child: currentUid == null
                ? const Center(child: Text("שגיאה בזיהוי המשתמש."))
                : StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getTasksCreatedBy(currentUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData) {
                        return const ShimmerLoading(cardHeight: 140, cardBorderRadius: 18);
                      }

                      List<TaskModel> tasks = snapshot.data!;

                      // Filter by date first
                      tasks = tasks.where((t) {
                        final tDate = t.dueDate.toDate();
                        return tDate.year == selectedDate.year &&
                            tDate.month == selectedDate.month &&
                            tDate.day == selectedDate.day;
                      }).toList();

                      // Then filter by status
                      if (selectedStatus != 'all') {
                        tasks = tasks
                            .where((t) => t.status == selectedStatus)
                            .toList();
                      }

                      // Filter by search query
                      if (_searchQuery.isNotEmpty) {
                        tasks = tasks
                            .where((t) =>
                                t.title.toLowerCase().contains(_searchQuery) ||
                                t.description.toLowerCase().contains(_searchQuery))
                            .toList();
                      }

                      if (tasks.isEmpty) {
                        return const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 40),
                            Text(
                              "אין משימות ליום זה",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "השתמש בכפתור 'יצירת משימה' כדי להוסיף אחת חדשה",
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        );
                      }

                      // Batch-fetch all assigned workers once
                      final allUserIds = tasks
                          .expand((t) => t.assignedTo)
                          .toSet()
                          .toList();

                      return FutureBuilder<List<UserModel>>(
                        future: _workerService.getUsersByIds(allUserIds),
                        builder: (context, usersSnapshot) {
                          final usersMap = <String, UserModel>{};
                          if (usersSnapshot.hasData) {
                            for (final user in usersSnapshot.data!) {
                              usersMap[user.uid] = user;
                            }
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: tasks.length,
                            itemBuilder: (context, index) =>
                                _buildTaskCard(tasks[index], usersMap),
                          );
                        },
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: const Icon(Icons.calendar_today,
                      size: 20, color: AppColors.primary),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.trim().toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'חיפוש משימה לפי שם...',
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: isSelected ? 4 : 0,
                ),
                child: FittedBox(
                  child: Text(label,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, Map<String, UserModel> usersMap) {
    final DateTime date = task.dueDate.toDate();
    final String time = DateFormat('HH:mm').format(date);
    final String dateFormatted = DateFormat('dd/MM/yyyy').format(date);

    // Resolve assigned workers from pre-fetched map
    final assignedUsers = task.assignedTo
        .where((id) => usersMap.containsKey(id))
        .map((id) => usersMap[id]!)
        .take(3)
        .toList();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(task: task)),
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
            // Status + time
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
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Avatars + date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: assignedUsers.map((user) {
                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      child: ProfileAvatar(
                        imageUrl: user.profilePicture,
                        radius: 16,
                      ),
                    );
                  }).toList(),
                ),
                Text(
                  dateFormatted,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildCardAction(
                  label: "ערוך",
                  icon: Icons.edit_outlined,
                  color: AppColors.primary,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => EditTaskScreen(task: task)),
                  ),
                ),
                const SizedBox(width: 8),
                _buildCardAction(
                  label: "מחק",
                  icon: Icons.delete_outline_rounded,
                  color: Colors.red.shade600,
                  onPressed: () => _confirmDeleteTask(task),
                ),
              ],
            ),
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
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCardAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: color.withOpacity(0.09),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: Size.zero,
      ),
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
