import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/reports/screens/attendance_summary_report.dart';
import 'package:park_janana/features/reports/screens/task_summary_report.dart';
import 'package:park_janana/features/reports/screens/worker_shift_report.dart';
import 'package:park_janana/features/reports/screens/workers_hours_report.dart';
import 'package:park_janana/features/reports/screens/task_distribution_report.dart';
import 'package:park_janana/features/reports/screens/shift_coverage_report.dart';
import 'package:park_janana/features/reports/screens/missing_clockout_report.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class ManagerReportsScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const ManagerReportsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<ManagerReportsScreen> createState() => _ManagerReportsScreenState();
}

class _ManagerReportsScreenState extends State<ManagerReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: TaskTheme.background,
        body: Column(
          children: [
            const UserHeader(),
            Container(
              color: TaskTheme.surface,
              child: TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                labelColor: TaskTheme.inProgress,
                unselectedLabelColor: TaskTheme.textSecondary,
                indicatorColor: TaskTheme.inProgress,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: _l10n.myReportsTitle),
                  Tab(text: _l10n.generalReportsTabLabel),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PersonalReportsTab(
                    userId: widget.userId,
                    userName: widget.userName,
                    profileUrl: widget.profileUrl,
                  ),
                  _GeneralReportsTab(
                    userId: widget.userId,
                    userName: widget.userName,
                    profileUrl: widget.profileUrl,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

// ─── Personal Reports Tab ──────────────────────────────────────────────────────

class _PersonalReportsTab extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const _PersonalReportsTab({
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<_PersonalReportsTab> createState() => _PersonalReportsTabState();
}

class _PersonalReportsTabState extends State<_PersonalReportsTab>
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_l10n.myReportsTitle, style: TaskTheme.heading1),
          const SizedBox(height: 4),
          Text(
            _l10n.personalReportsSubtitle,
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
          const SizedBox(height: 24),
          _buildCard(
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
          _buildCard(
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
          _buildCard(
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
    );
  }

  Widget _buildCard({
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

// ─── General Reports Tab ───────────────────────────────────────────────────────

class _GeneralReportsTab extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const _GeneralReportsTab({
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<_GeneralReportsTab> createState() => _GeneralReportsTabState();
}

class _GeneralReportsTabState extends State<_GeneralReportsTab>
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_l10n.generalReportsTabLabel, style: TaskTheme.heading1),
          const SizedBox(height: 4),
          Text(
            _l10n.generalReportsSubtitle,
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
          const SizedBox(height: 24),
          _buildCard(
            index: 0,
            icon: PhosphorIconsRegular.users,
            title: _l10n.workersHoursTitle,
            description: _l10n.workersHoursDescription,
            gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WorkersHoursReport()),
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            index: 1,
            icon: PhosphorIconsRegular.chartBar,
            title: _l10n.taskDistributionTitle,
            description: _l10n.taskDistributionDescription,
            gradientColors: const [Color(0xFFF59E0B), Color(0xFFD97706)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TaskDistributionReport()),
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            index: 2,
            icon: PhosphorIconsRegular.buildings,
            title: _l10n.shiftCoverageTitle,
            description: _l10n.shiftCoverageDescription,
            gradientColors: const [Color(0xFF10B981), Color(0xFF059669)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShiftCoverageReport()),
            ),
          ),
          const SizedBox(height: 14),
          _buildCard(
            index: 3,
            icon: PhosphorIconsRegular.signIn,
            title: _l10n.missingCheckoutsTitle,
            description: _l10n.missingClockoutsDescription,
            gradientColors: const [Color(0xFFEF4444), Color(0xFFDC2626)],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MissingClockoutReport()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
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
        (0.6 + index * 0.15).clamp(0.0, 1.0),
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

// ─── Shared Card Tile ──────────────────────────────────────────────────────────

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
              right: BorderSide(color: widget.gradientColors[0], width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
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
