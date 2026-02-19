import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/task_theme.dart';
import '../widgets/task_status_badge.dart';
import '../widgets/task_priority_indicator.dart';
import 'edit_task_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  final TextEditingController _commentController = TextEditingController();

  late TabController _tabController;
  late TaskModel _task;
  List<UserModel> _workers = [];
  final Map<String, String> _userNameCache = {};
  bool _isSubmitting = false;

  String? get _currentUid => context.read<AppAuthProvider>().uid;

  bool get _isManager => _task.createdBy == _currentUid;

  bool get _isWorker => _task.assignedTo.contains(_currentUid ?? '');

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final updated = await _taskService.getTaskById(widget.task.id);
    if (updated != null) {
      final workers = await _workerService.getUsersByIds(updated.assignedTo);
      if (mounted) {
        setState(() {
          _task = updated;
          _workers = workers;
          for (final w in workers) {
            _userNameCache[w.uid] = w.fullName;
          }
        });
      }
    }
  }

  Future<String> _getUserName(String uid) async {
    if (_userNameCache.containsKey(uid)) return _userNameCache[uid]!;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      final name = doc.data()?['fullName'] ?? 'משתמש';
      _userNameCache[uid] = name;
      return name;
    } catch (_) {
      return 'משתמש';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TaskTheme.background,
        body: StreamBuilder<TaskModel?>(
          stream: _taskService.getTaskStream(widget.task.id),
          initialData: _task,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              _task = snapshot.data!;
            }

            return Column(
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: UserHeader(),
                ),
                if (_isManager)
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz_rounded),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditTaskScreen(task: _task),
                                ),
                              ).then((_) => _fetchData());
                            } else if (value == 'delete') {
                              _confirmDelete();
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('ערוך משימה'),
                                  ],
                                )),
                            const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        size: 18, color: TaskTheme.overdue),
                                    SizedBox(width: 8),
                                    Text('מחק משימה',
                                        style: TextStyle(color: TaskTheme.overdue)),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(),
                            _buildDiscussionTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusXL),
        boxShadow: TaskTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_task.title, style: TaskTheme.heading1),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TaskStatusBadge(status: _task.status),
              TaskPriorityIndicator(priority: _task.priority),
              if (_task.department != 'general')
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: TaskTheme.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    TaskTheme.departmentLabel(_task.department),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TaskTheme.primary,
                    ),
                  ),
                ),
            ],
          ),
          if (_workers.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _workers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final w = _workers[i];
                  final status = _task.workerStatusFor(w.uid);
                  final statusColor = TaskTheme.statusColor(status);

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: statusColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            ProfileAvatar(
                              imageUrl: w.profilePicture,
                              radius: 14,
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          w.fullName.split(' ').first,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        border: Border.all(color: TaskTheme.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: TaskTheme.primary,
          borderRadius: BorderRadius.circular(TaskTheme.radiusM - 2),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: TaskTheme.textSecondary,
        labelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'סקירה'),
          Tab(text: 'דיון'),
        ],
      ),
    );
  }

  // ─── Overview Tab ──────────────────────────────────────────

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(
            icon: Icons.description_outlined,
            title: 'תיאור',
            child: Text(
              _task.description.isNotEmpty
                  ? _task.description
                  : 'אין תיאור למשימה זו',
              style: TaskTheme.body.copyWith(
                color: _task.description.isNotEmpty
                    ? TaskTheme.textPrimary
                    : TaskTheme.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.info_outline_rounded,
            title: 'פרטים',
            child: Column(
              children: [
                _buildDetailRow(
                  'תאריך יעד',
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(_task.dueDate.toDate()),
                  Icons.calendar_today_rounded,
                ),
                const Divider(height: 20, color: TaskTheme.divider),
                _buildDetailRow(
                  'עדיפות',
                  TaskTheme.priorityLabel(_task.priority),
                  TaskTheme.priorityIcon(_task.priority),
                  color: TaskTheme.priorityColor(_task.priority),
                ),
                const Divider(height: 20, color: TaskTheme.divider),
                _buildDetailRow(
                  'מחלקה',
                  TaskTheme.departmentLabel(_task.department),
                  Icons.business_rounded,
                ),
                const Divider(height: 20, color: TaskTheme.divider),
                _buildDetailRow(
                  'נוצרה',
                  DateFormat('dd/MM/yyyy').format(_task.createdAt.toDate()),
                  Icons.schedule_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            icon: Icons.group_outlined,
            title: 'עובדים (${_workers.length})',
            child: Column(
              children: _workers.map((w) {
                final status = _task.workerStatusFor(w.uid);
                return _buildWorkerRow(w, status);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: TaskTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: TaskTheme.primary),
              const SizedBox(width: 8),
              Text(title, style: TaskTheme.heading3),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? TaskTheme.textTertiary),
        const SizedBox(width: 8),
        Text(label, style: TaskTheme.body),
        const Spacer(),
        Text(
          value,
          style: TaskTheme.label.copyWith(
            color: color ?? TaskTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerRow(UserModel worker, String status) {
    final statusColor = TaskTheme.statusColor(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ProfileAvatar(
            imageUrl: worker.profilePicture,
            radius: 18,
            backgroundColor: TaskTheme.primary.withOpacity(0.1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.fullName, style: TaskTheme.label),
                Text(worker.role, style: TaskTheme.caption),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              TaskTheme.statusLabel(status),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Discussion Tab ────────────────────────────────────────

  Widget _buildDiscussionTab() {
    final comments = _task.comments;

    if (comments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 48, color: TaskTheme.textTertiary.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('אין תגובות עדיין',
                style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: comments.length,
      itemBuilder: (context, i) {
        final comment = comments[i];
        final message = comment['message'] ?? '';
        final uid = comment['by'] ?? '';
        final timestamp =
            comment['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
        final time = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final isMe = uid == _currentUid;

        return FutureBuilder<String>(
          future: _getUserName(uid),
          builder: (context, snap) {
            final name = snap.data ?? '...';
            return _buildChatBubble(name, message, time, isMe);
          },
        );
      },
    );
  }

  Widget _buildChatBubble(
      String name, String message, DateTime time, bool isMe) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: TaskTheme.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TaskTheme.textSecondary)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(time),
                  style: TaskTheme.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? TaskTheme.primary.withOpacity(0.1)
                  : TaskTheme.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 4 : 18),
                bottomRight: Radius.circular(isMe ? 18 : 4),
              ),
              border: isMe ? null : Border.all(color: TaskTheme.border),
              boxShadow: TaskTheme.softShadow,
            ),
            child: Text(
              message,
              style: TaskTheme.body.copyWith(
                color: TaskTheme.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Bar ────────────────────────────────────────────

  Widget _buildBottomBar() {
    final uid = _currentUid ?? '';
    final workerStatus = _task.workerStatusFor(uid);
    final isOnDiscussionTab = _tabController.index == 1;
    final showWorkerAction = _isWorker && workerStatus != 'done';

    // Nothing to show if not on discussion tab and no worker action needed
    if (!isOnDiscussionTab && !showWorkerAction) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        boxShadow: TaskTheme.topBarShadow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showWorkerAction) ...[
              _buildWorkerActionButton(workerStatus),
              if (isOnDiscussionTab) const SizedBox(height: 12),
            ],
            if (isOnDiscussionTab)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: TaskTheme.background,
                        borderRadius: BorderRadius.circular(TaskTheme.radiusXXL),
                        border: Border.all(color: TaskTheme.border),
                        boxShadow: TaskTheme.softShadow,
                      ),
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'כתוב תגובה...',
                          hintStyle: TextStyle(
                              color: TaskTheme.textTertiary, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 18, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: TaskTheme.buttonShadow(TaskTheme.primary),
                    ),
                    child: Material(
                      color: TaskTheme.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isSubmitting ? null : _addComment,
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerActionButton(String workerStatus) {
    final isStart = workerStatus == 'pending';
    final color = isStart ? TaskTheme.inProgress : TaskTheme.done;
    final nextStatus = isStart ? 'in_progress' : 'done';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.85)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: TaskTheme.buttonShadow(color),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          onTap: () => _updateWorkerStatus(nextStatus),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isStart ? Icons.rocket_launch_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  isStart ? 'להתחיל לעבוד' : 'סיימתי את המשימה',
                  style: const TextStyle(
                    fontSize: 16,
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

  Future<void> _updateWorkerStatus(String newStatus) async {
    if (_currentUid == null) return;
    await _taskService.updateWorkerStatus(_task.id, _currentUid!, newStatus);
    await _fetchData();
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty ||
        _isSubmitting ||
        _currentUid == null) return;

    setState(() => _isSubmitting = true);
    try {
      await _taskService.addComment(_task.id, {
        'by': _currentUid,
        'message': _commentController.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentController.clear();
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בשליחת תגובה')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('מחיקת משימה'),
          content: Text('למחוק את "${_task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () async {
                await _taskService.deleteTask(_task.id);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('מחק',
                  style: TextStyle(color: TaskTheme.overdue)),
            ),
          ],
        ),
      ),
    );
  }
}
