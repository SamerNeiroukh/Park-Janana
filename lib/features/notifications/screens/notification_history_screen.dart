// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/screens/manager_weekly_schedule_screen.dart';
import 'package:park_janana/features/shifts/screens/shift_details_screen.dart';
import 'package:park_janana/features/shifts/screens/shifts_screen.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/newsfeed/screens/newsfeed_screen.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/screens/manager_task_board_screen.dart';
import 'package:park_janana/features/tasks/screens/task_details_screen.dart';
import 'package:park_janana/features/tasks/screens/worker_task_timeline_screen.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';
import 'package:park_janana/features/workers/screens/manage_workers_screen.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  // ── Config ───────────────────────────────────────────────────────────────
  static const int _maxItems = 100;

  // ── State ────────────────────────────────────────────────────────────────
  String? _uid;
  String? _userRole;
  bool _isMarkingAll = false;

  bool get _isManager =>
      _userRole == 'manager' || _userRole == 'owner' || _userRole == 'co_owner' || _userRole == 'admin';

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AppAuthProvider>();
      _uid = auth.uid;
      _userRole = auth.userRole;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TaskTheme.background,
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('התראות', style: TaskTheme.heading2),
          ),
          if (_uid != null && !_isMarkingAll)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16),
              label: const Text('סמן הכל כנקרא'),
              style: TextButton.styleFrom(
                foregroundColor: TaskTheme.primary,
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          if (_isMarkingAll)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  // ── Body (stream) ─────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_uid)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(_maxItems)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: TaskTheme.primary));
        }

        if (snap.hasError) {
          debugPrint('Notification stream error: ${snap.error}');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: TaskTheme.overdue),
                const SizedBox(height: 12),
                const Text('שגיאה בטעינת ההתראות', style: TaskTheme.body),
                const SizedBox(height: 6),
                Text('${snap.error}',
                    style: TaskTheme.caption, textAlign: TextAlign.center),
              ],
            ),
          );
        }

        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final item = _NotifItem.fromDoc(doc);
            return _buildTile(item, doc.reference);
          },
        );
      },
    );
  }

  // ── Tile ──────────────────────────────────────────────────────────────────

  Widget _buildTile(_NotifItem item, DocumentReference ref) {
    final cfg = _typeConfig(item.type);

    return GestureDetector(
      onTap: () => _onTap(item, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: item.isRead
              ? TaskTheme.surface
              : cfg.color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          boxShadow: TaskTheme.softShadow,
          border: Border(
            right: BorderSide(
              color: cfg.color,
              width: item.isRead ? 3 : 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(item.isRead ? 0.10 : 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(item.title, style: TaskTheme.heading3),
                        ),
                        if (!item.isRead) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: cfg.color,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'חדש',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: TaskTheme.body
                            .copyWith(color: TaskTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(_relativeTime(item.createdAt), style: TaskTheme.caption),
                  ],
                ),
              ),
              // Chevron hint if tappable
              if (_isTappable(item.type))
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 18, color: TaskTheme.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tap handler ───────────────────────────────────────────────────────────

  Future<void> _onTap(_NotifItem item, DocumentReference ref) async {
    // Mark as read first
    if (!item.isRead) {
      ref.update({'isRead': true}).catchError((_) {});
    }

    if (!_isTappable(item.type) || item.entityId.isEmpty) return;

    switch (item.type) {
      case 'shift_assigned':
      case 'shift_update':
      case 'shift_removed':
      case 'shift_cancelled':
      case 'shift_rejected':
        await _openShift(item.entityId);
      case 'shift_message':
        await _openShift(item.entityId, initialTab: 2);
      case 'task_assigned':
      case 'task_approved':
        await _openTask(item.entityId);
      case 'task_review_requested':
        _openManagerBoardHighlight(item.entityId);
      case 'task_comment':
        await _openTask(item.entityId, initialTab: 1, withBase: false);
      case 'post_comment':
        _openPostDetail(item.entityId);
      case 'new_user_pending':
        if (_isManager) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ManageWorkersScreen()),
          );
        }
    }
  }

  Future<void> _openShift(String shiftId, {int initialTab = 0}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final shift = ShiftModel.fromMap(doc.id, doc.data()!);
      if (!mounted) return;

      if (!_isManager) {
        // Worker: My Shifts screen jumping to the shift's date, popup auto-opened.
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftsScreen(initialShift: shift),
          ),
        );
      } else {
        // Manager/owner/admin: weekly overview with shift details stacked on top.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManagerWeeklyScheduleScreen()),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftDetailsScreen(
              shift: shift,
              shiftService: ShiftService(),
              workerService: WorkerService(),
              initialTab: initialTab,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('_openShift error: $e');
    }
  }

  Future<void> _openTask(String taskId, {int initialTab = 0, bool withBase = true}) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final task = TaskModel.fromMap(doc.id, doc.data()!);
      if (!mounted) return;

      if (withBase) {
        if (!_isManager) {
          // Worker: My Tasks timeline as base, task details on top.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkerTaskTimelineScreen()),
          );
        } else {
          // Manager: "המשימות שלי" tab (index 1), task details on top.
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const ManagerTaskBoardScreen(initialTab: 1)),
          );
        }
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task, initialTab: initialTab)),
      );
    } catch (e) {
      debugPrint('_openTask error: $e');
    }
  }

  void _openPostDetail(String postId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsfeedScreen(initialPostId: postId),
      ),
    );
  }

  void _openManagerBoardHighlight(String taskId) {
    if (!_isManager) {
      debugPrint('ManagerBoardHighlight blocked — role=$_userRole is not authorized');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManagerTaskBoardScreen(
          initialTab: 0,
          highlightTaskId: taskId,
        ),
      ),
    );
  }

  // ── Mark all as read ──────────────────────────────────────────────────────

  Future<void> _markAllAsRead() async {
    if (_uid == null || _isMarkingAll) return;
    setState(() => _isMarkingAll = true);

    try {
      final unread = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(_uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in unread.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('_markAllAsRead error: $e');
    }

    if (mounted) setState(() => _isMarkingAll = false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isTappable(String type) {
    if (type == 'task_review_requested') return _isManager;
    if (type.startsWith('shift_') || type.startsWith('task_')) return true;
    if (type == 'new_user_pending') return _isManager;
    if (type == 'post_comment') return true;
    return false;
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays == 1) return 'אתמול';
    return 'לפני ${diff.inDays} ימים';
  }

  _TypeConfig _typeConfig(String type) {
    if (type.startsWith('shift_')) {
      return const _TypeConfig(
        icon: Icons.schedule_rounded,
        color: Color(0xFF4F46E5),
      );
    }
    if (type.startsWith('task_')) {
      return const _TypeConfig(
        icon: Icons.task_alt_rounded,
        color: Color(0xFF8B5CF6),
      );
    }
    if (type == 'new_user_pending' ||
        type == 'worker_approved' ||
        type == 'worker_rejected') {
      return const _TypeConfig(
        icon: Icons.person_rounded,
        color: Color(0xFF059669),
      );
    }
    if (type == 'post_comment') {
      return const _TypeConfig(
        icon: Icons.newspaper_rounded,
        color: Color(0xFFF59E0B),
      );
    }
    return const _TypeConfig(
      icon: Icons.notifications_rounded,
      color: TaskTheme.primary,
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text('אין התראות',
              style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary)),
          const SizedBox(height: 6),
          const Text('התראות חדשות יופיעו כאן', style: TaskTheme.caption),
        ],
      ),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _NotifItem {
  final String id;
  final String type;
  final String title;
  final String body;
  final String entityId;
  final bool isRead;
  final DateTime createdAt;

  const _NotifItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.entityId,
    required this.isRead,
    required this.createdAt,
  });

  factory _NotifItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['createdAt'] as Timestamp?;
    return _NotifItem(
      id: doc.id,
      type: d['type'] as String? ?? 'general',
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      entityId: d['entityId'] as String? ?? '',
      isRead: d['isRead'] as bool? ?? false,
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  const _TypeConfig({required this.icon, required this.color});
}
