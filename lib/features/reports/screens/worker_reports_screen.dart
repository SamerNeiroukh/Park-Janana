import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/reports/screens/attendance_summary_report.dart';
import 'package:park_janana/features/reports/screens/task_summary_report.dart';
import 'package:park_janana/features/reports/screens/worker_shift_report.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class WorkerReportsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const WorkerReportsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<WorkerReportsScreen> createState() => _WorkerReportsScreenState();
}

class _WorkerReportsScreenState extends State<WorkerReportsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: TaskTheme.background,
        body: Column(
          children: [
            const UserHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_l10n.reportsOfWorker(widget.userName), style: TaskTheme.heading1),
                    const SizedBox(height: 4),
                    Text(
                      _l10n.workerReportsSubtitle,
                      style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
                    ),
                    const SizedBox(height: 20),
                    _PerformanceSummaryCard(
                      userId: widget.userId,
                    ),
                    const SizedBox(height: 20),
                    _buildReportCard(
                      index: 0,
                      icon: PhosphorIconsRegular.clock,
                      title: _l10n.attendanceReportTitle,
                      description: _l10n.attendanceReportDescription,
                      gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceSummaryScreen(
                            userId: widget.userId,
                            userName: widget.userName,
                            profileUrl: widget.profileUrl,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildReportCard(
                      index: 1,
                      icon: PhosphorIconsRegular.checkSquare,
                      title: _l10n.taskReportCard,
                      description: _l10n.taskReportDescription,
                      gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskSummaryReport(
                            userId: widget.userId,
                            userName: widget.userName,
                            profileUrl: widget.profileUrl,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildReportCard(
                      index: 2,
                      icon: PhosphorIconsRegular.clock,
                      title: _l10n.shiftReportTitle,
                      description: _l10n.shiftReportDescription,
                      gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkerShiftReport(
                            uid: widget.userId,
                            fullName: widget.userName,
                            profilePicture: widget.profileUrl,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildReportCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    final animation = CurvedAnimation(
      parent: _animController,
      curve: Interval(
        index * 0.15,
        0.6 + index * 0.15,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(animation),
        child: _ReportCardTile(
          icon: icon,
          title: title,
          description: description,
          gradientColors: gradientColors,
          onTap: onTap,
        ),
      ),
    );
  }
}

// ── Performance Summary ────────────────────────────────────────────────────

class _PerformanceSummaryCard extends StatefulWidget {
  final String userId;
  const _PerformanceSummaryCard({required this.userId});

  @override
  State<_PerformanceSummaryCard> createState() =>
      _PerformanceSummaryCardState();
}

class _PerformanceSummaryCardState extends State<_PerformanceSummaryCard> {
  late AppLocalizations _l10n;
  bool _loading = true;
  double _hoursThisMonth = 0;
  int _daysThisMonth = 0;
  int _totalTasks = 0;
  int _completedTasks = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final now = DateTime.now();
    final docId =
        '${widget.userId}_${now.year}_${now.month.toString().padLeft(2, '0')}';
    try {
      // Attendance
      final attSnap = await FirebaseFirestore.instance
          .collection(AppConstants.attendanceCollection)
          .doc(docId)
          .get();
      if (attSnap.exists && attSnap.data() != null) {
        final model = AttendanceModel.fromMap(attSnap.data()!, docId);
        _hoursThisMonth = model.totalHoursWorked;
        _daysThisMonth = model.daysWorked;
      }

      // Tasks
      final taskSnap = await FirebaseFirestore.instance
          .collection(AppConstants.tasksCollection)
          .where('assignedTo', arrayContains: widget.userId)
          .get();
      _totalTasks = taskSnap.docs.length;
      _completedTasks = taskSnap.docs
          .where((d) => d.data()['status'] == 'completed')
          .length;
    } catch (e) {
      debugPrint('_PerformanceSummaryCard fetch error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: TaskTheme.surface,
          borderRadius: BorderRadius.circular(TaskTheme.radiusL),
          boxShadow: TaskTheme.cardShadow,
        ),
        child: const Center(
            child: CircularProgressIndicator(color: TaskTheme.primary)),
      );
    }

    final completionRate =
        _totalTasks > 0 ? (_completedTasks / _totalTasks * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(PhosphorIconsRegular.chartBar, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(_l10n.performanceSummaryTitle,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            _metric(PhosphorIconsRegular.clock,
                _l10n.hoursWithValue(_hoursThisMonth.toStringAsFixed(1)), _l10n.presenceLabel),
            _divider(),
            _metric(PhosphorIconsRegular.calendarBlank, _l10n.daysWithValue(_daysThisMonth), _l10n.atWorkLabel),
            _divider(),
            _metric(PhosphorIconsRegular.checkSquare, '$completionRate%', _l10n.tasksCompletedLabel),
          ]),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1, height: 48, color: Colors.white.withValues(alpha: 0.2));
  }
}

class _ReportCardTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _ReportCardTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<_ReportCardTile> createState() => _ReportCardTileState();
}

class _ReportCardTileState extends State<_ReportCardTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            color: TaskTheme.surface,
            borderRadius: BorderRadius.circular(TaskTheme.radiusL),
            boxShadow: TaskTheme.cardShadow,
            border: Border(
              right: BorderSide(
                color: widget.gradientColors[0],
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.gradientColors,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: widget.gradientColors[0].withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 16),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: TaskTheme.heading3),
                      const SizedBox(height: 4),
                      Text(
                        widget.description,
                        style: TaskTheme.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: TaskTheme.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.caretRight,
                    color: TaskTheme.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
