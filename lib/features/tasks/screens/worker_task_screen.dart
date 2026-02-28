// 💡 Modernized UI Enhancements for WorkerTaskScreen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/features/tasks/screens/worker_task_details.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/core/widgets/shimmer_loading.dart';

class WorkerTaskScreen extends StatefulWidget {
  const WorkerTaskScreen({super.key});

  @override
  State<WorkerTaskScreen> createState() => _WorkerTaskScreenState();
}

class _WorkerTaskScreenState extends State<WorkerTaskScreen> {
  final TaskService _taskService = TaskService();

  String _selectedStatus = 'all';
  DateTime _selectedDate = DateTime.now();

  Future<void> _refreshTasks(String uid) async {
    final snapshot = await _taskService.getTasksForUser(uid).first;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentUid = authProvider.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const UserHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10.0),
            child: Text("המשימות שלי", style: AppTheme.screenTitle),
          ),
          _buildDateNavigation(),
          _buildStatusFilterButtons(),
          Expanded(
            child: currentUid == null
                ? const Center(child: Text("שגיאה בזיהוי המשתמש."))
                : StreamBuilder<List<TaskModel>>(
                    stream: _taskService.getTasksForUser(currentUid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ShimmerLoading(cardHeight: 140, cardBorderRadius: 20);
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text("אין משימות פעילות."));
                      }
                      List<TaskModel> tasks = snapshot.data!;
                      tasks = tasks.where((t) {
                        final tDate = t.dueDate.toDate();
                        return tDate.year == _selectedDate.year &&
                            tDate.month == _selectedDate.month &&
                            tDate.day == _selectedDate.day;
                      }).toList();
                      if (_selectedStatus != 'all') {
                        tasks = tasks.where((t) {
                          final workerStatus = t.workerProgress[currentUid]
                                  ?['status'] ??
                              'pending';
                          return workerStatus == _selectedStatus;
                        }).toList();
                      }
                      return RefreshIndicator(
                        onRefresh: () => _refreshTasks(currentUid),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) =>
                              _buildTaskCard(tasks[index], currentUid),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildDateNavigation() {
    final String formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left, size: 30),
              onPressed: () => _changeDate(-1)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(colors: [Colors.white, Colors.grey.shade100]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)
              ],
            ),
            child: Row(
              children: [
                Text(formattedDate,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
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
              onPressed: () => _changeDate(1)),
        ],
      ),
    );
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale("he", "IL"),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildStatusFilterButtons() {
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
          final isSelected = _selectedStatus == data['value'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _selectedStatus = data['value']),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected
                        ? data['color']
                        : data['color'].withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: isSelected ? 4 : 0,
                  ),
                  child: FittedBox(
                    child: Text(data['label'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, String uid) {
    final String workerStatus =
        task.workerProgress[uid]?['status'] ?? 'pending';
    final DateTime date = task.dueDate.toDate();
    final String time = DateFormat('HH:mm').format(date);
    final Color bgColor = workerStatus == 'done'
        ? Colors.green.shade50
        : workerStatus == 'in_progress'
            ? Colors.orange.shade50
            : Colors.white;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkerTaskDetailsScreen(task: task),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildWorkerStatusChip(workerStatus),
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
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            if (workerStatus != 'done') ...[
              LiveCountdownTimer(dueDate: task.dueDate.toDate()),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _buildActionButton(task, workerStatus, uid),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerStatusChip(String status) {
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
      labelPadding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: color.withOpacity(0.15),
      label: Text(label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActionButton(TaskModel task, String currentStatus, String uid) {
    final bool isPending = currentStatus == 'pending';
    final Color fromColor =
        isPending ? const Color(0xFF6366F1) : const Color(0xFF059669);
    final Color toColor =
        isPending ? const Color(0xFF818CF8) : const Color(0xFF34D399);
    final IconData icon =
        isPending ? Icons.play_arrow_rounded : Icons.check_circle_rounded;
    final String label = isPending ? 'התחל משימה' : 'סיים משימה';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [fromColor, toColor],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: fromColor.withOpacity(0.38),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.15),
          onTap: () => _updateStatus(task, isPending ? 'in_progress' : 'done', uid),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(TaskModel task, String status, String uid) async {
    await _taskService.updateWorkerStatus(task.id, uid, status);
    await _refreshTasks(uid);
  }
}

class LiveCountdownTimer extends StatefulWidget {
  final DateTime dueDate;
  const LiveCountdownTimer({super.key, required this.dueDate});

  @override
  State<LiveCountdownTimer> createState() => _LiveCountdownTimerState();
}

class _LiveCountdownTimerState extends State<LiveCountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateRemainingTime());
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.dueDate.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = widget.dueDate.day == now.day &&
        widget.dueDate.month == now.month &&
        widget.dueDate.year == now.year;

    String label;
    Color color;

    if (!isToday) {
      final days = widget.dueDate.difference(now).inDays;
      label = days >= 0 ? "בעוד $days ימים" : "איחור של ${days.abs()} ימים";
      color = days >= 0 ? Colors.black : Colors.red;
    } else if (_remaining.isNegative) {
      label = "איחור";
      color = Colors.red;
    } else {
      final hours = _remaining.inHours;
      final minutes = _remaining.inMinutes % 60;
      final seconds = _remaining.inSeconds % 60;
      label =
          "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      color = _remaining.inMinutes < 60 ? Colors.red : Colors.green;
    }

    return Row(
      children: [
        Image.asset('assets/gifs/sand_watch1.gif', height: 28, width: 28),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
