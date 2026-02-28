import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/task_model.dart';
import '../providers/task_timeline_provider.dart';
import '../theme/task_theme.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';

class WorkerTaskTimelineScreen extends StatefulWidget {
  const WorkerTaskTimelineScreen({super.key});

  @override
  State<WorkerTaskTimelineScreen> createState() =>
      _WorkerTaskTimelineScreenState();
}

class _WorkerTaskTimelineScreenState extends State<WorkerTaskTimelineScreen> {
  late final TaskTimelineProvider _provider;
  bool _showAllCompleted = false;

  @override
  void initState() {
    super.initState();
    _provider = TaskTimelineProvider();
    final uid = context.read<AppAuthProvider>().uid;
    if (uid != null) _provider.init(uid);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: TaskTheme.background,
          body: Column(
            children: [
              const Directionality(
                textDirection: TextDirection.ltr,
                child: UserHeader(),
              ),
              Expanded(
                child: Consumer<TaskTimelineProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: TaskTheme.primary),
                      );
                    }

                    return RefreshIndicator(
                      color: TaskTheme.primary,
                      onRefresh: () async {
                        final uid = context.read<AppAuthProvider>().uid;
                        if (uid != null) provider.init(uid);
                      },
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          _buildProgressHeader(provider),
                          const SizedBox(height: 20),

                          // Overdue section
                          if (provider.overdueTasks.isNotEmpty) ...[
                            _buildSection(
                              title: 'באיחור',
                              icon: Icons.warning_amber_rounded,
                              color: TaskTheme.overdue,
                              tasks: provider.overdueTasks,
                              provider: provider,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Today section
                          if (provider.todayTasks.isNotEmpty) ...[
                            _buildSection(
                              title: 'להיום',
                              icon: Icons.today_rounded,
                              color: TaskTheme.pending,
                              tasks: provider.todayTasks,
                              provider: provider,
                              showActions: true,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Upcoming section
                          if (provider.upcomingTasks.isNotEmpty) ...[
                            _buildSection(
                              title: 'הקרובות',
                              icon: Icons.event_rounded,
                              color: TaskTheme.inProgress,
                              tasks: provider.upcomingTasks,
                              provider: provider,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Completed section
                          if (provider.completedTasks.isNotEmpty)
                            _buildCompletedSection(provider),

                          // Empty state
                          if (provider.overdueTasks.isEmpty &&
                              provider.todayTasks.isEmpty &&
                              provider.upcomingTasks.isEmpty &&
                              provider.completedTasks.isEmpty)
                            _buildEmptyState(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(TaskTimelineProvider provider) {
    final progress = provider.todayProgress;
    final completed = provider.todayCompleted;
    final total = provider.todayTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TaskTheme.primary, TaskTheme.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(TaskTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: TaskTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Progress ring
          SizedBox(
            width: 72,
            height: 72,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _ProgressRingPainter(
                    progress: value,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    progressColor: Colors.white,
                    strokeWidth: 6,
                  ),
                  child: Center(
                    child: Text(
                      '${(value * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'המשימות שלי',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == 0
                      ? 'אין משימות להיום'
                      : '$completed מתוך $total הושלמו היום',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<TaskModel> tasks,
    required TaskTimelineProvider provider,
    bool showActions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TaskTheme.heading3.copyWith(color: color),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Task cards
        ...tasks.map((task) => _buildTaskWithActions(task, provider, showActions)),
      ],
    );
  }

  Widget _buildTaskWithActions(
      TaskModel task, TaskTimelineProvider provider, bool showActions) {
    final uid = context.read<AppAuthProvider>().uid ?? '';
    final workerStatus = task.workerStatusFor(uid);

    Widget? actionWidget;
    if (workerStatus == 'pending_review') {
      actionWidget = _buildPendingReviewBanner();
    } else if (workerStatus != 'done') {
      actionWidget = _buildQuickAction(task, workerStatus, provider);
    }

    return TaskCard(
      task: task,
      currentUserId: uid,
      actionWidget: actionWidget,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
      ),
    );
  }

  Widget _buildPendingReviewBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 18, color: Color(0xFFF59E0B)),
          SizedBox(width: 8),
          Text(
            'ממתין לאישור מנהל',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      TaskModel task, String workerStatus, TaskTimelineProvider provider) {
    final isStart = workerStatus == 'pending';
    final Color fromColor =
        isStart ? const Color(0xFF6366F1) : const Color(0xFFF59E0B);
    final Color toColor =
        isStart ? const Color(0xFF818CF8) : const Color(0xFFFBBF24);
    final String label = isStart ? 'התחל לעבוד' : 'שלח לאישור מנהל';
    final IconData icon =
        isStart ? Icons.rocket_launch_rounded : Icons.send_rounded;
    final String nextStatus = isStart ? 'in_progress' : 'pending_review';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [fromColor, toColor],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
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
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          splashColor: Colors.white.withOpacity(0.15),
          onTap: () => provider.updateStatus(task.id, nextStatus),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 17, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
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

  Widget _buildCompletedSection(TaskTimelineProvider provider) {
    final tasks = provider.completedTasks;
    final displayTasks =
        _showAllCompleted ? tasks : tasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TaskTheme.done.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: TaskTheme.done),
            ),
            const SizedBox(width: 10),
            Text(
              'הושלמו',
              style: TaskTheme.heading3.copyWith(color: TaskTheme.done),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TaskTheme.done.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TaskTheme.done,
                ),
              ),
            ),
            const Spacer(),
            if (tasks.length > 3)
              GestureDetector(
                onTap: () =>
                    setState(() => _showAllCompleted = !_showAllCompleted),
                child: Text(
                  _showAllCompleted ? 'הצג פחות' : 'הצג הכל',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TaskTheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayTasks.map((task) => TaskCard(
              task: task,
              compact: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailsScreen(task: task),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: TaskTheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 56,
                color: TaskTheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'אין משימות כרגע',
              style: TaskTheme.heading3.copyWith(color: TaskTheme.textTertiary),
            ),
            const SizedBox(height: 8),
            Text(
              'משימות חדשות יופיעו כאן',
              style: TaskTheme.body,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
