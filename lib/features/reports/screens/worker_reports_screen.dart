import 'package:flutter/material.dart';
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('הדוחות שלי', style: TaskTheme.heading1),
                    const SizedBox(height: 4),
                    Text(
                      'צפייה בנתוני נוכחות, משימות ומשמרות',
                      style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
                    ),
                    const SizedBox(height: 24),
                    _buildReportCard(
                      index: 0,
                      icon: Icons.access_time_rounded,
                      title: 'דו״ח נוכחות',
                      description: 'שעות עבודה, ימי נוכחות וסיכום חודשי',
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
                      icon: Icons.task_alt_rounded,
                      title: 'דו״ח משימות',
                      description: 'סטטוס משימות, התקדמות ואחוזי ביצוע',
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
                      icon: Icons.schedule_rounded,
                      title: 'דו״ח משמרות',
                      description: 'היסטוריית משמרות, אישורים והחלטות',
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
                        color: widget.gradientColors[0].withOpacity(0.3),
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
                    Icons.chevron_right_rounded,
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
