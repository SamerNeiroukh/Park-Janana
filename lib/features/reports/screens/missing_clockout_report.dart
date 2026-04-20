import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/attendance/screens/attendance_correction_screen.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/reports/services/report_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class MissingClockoutReport extends StatefulWidget {
  const MissingClockoutReport({super.key});

  @override
  State<MissingClockoutReport> createState() => _MissingClockoutReportState();
}

class _MissingClockoutReportState extends State<MissingClockoutReport> {
  late DateTime _selectedMonth;
  late AppLocalizations _l10n;
  late String _localeCode;
  bool _isLoading = true;

  // Workers who have at least one missing clock-out this month.
  List<_WorkerMissingEntry> _entries = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    _localeCode = Localizations.localeOf(context).languageCode;
  }

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final all = await ReportService.getAllWorkersAttendanceByMonth(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      final entries = <_WorkerMissingEntry>[];
      for (final record in all) {
        final missing = record.sessions
            .where((s) => s.clockIn == s.clockOut || s.hoursWorked >= 16)
            .toList();
        if (missing.isNotEmpty) {
          entries.add(_WorkerMissingEntry(
            userId: record.userId,
            userName: record.userName,
            missingSessions: missing,
          ));
        }
      }

      // Sort by most missing first.
      entries.sort((a, b) =>
          b.missingSessions.length.compareTo(a.missingSessions.length));

      if (mounted) setState(() { _entries = entries; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _entries = []; _isLoading = false; });
    }
  }

  void _onMonthChanged(DateTime m) {
    setState(() => _selectedMonth = m);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskTheme.background,
      body: Column(
        children: [
          const UserHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(PhosphorIconsRegular.signIn,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(_l10n.missingCheckoutsTitle, style: TaskTheme.heading2),
                ],
              ),
            ),
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            if (_isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_entries.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: RefreshIndicator(
                  color: TaskTheme.overdue,
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      children: [
                        _buildStatRow(),
                        const SizedBox(height: 16),
                        _buildWorkerList(),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: TaskTheme.done.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(PhosphorIconsRegular.checkCircle,
                size: 56, color: TaskTheme.done),
          ),
          const SizedBox(height: 16),
          Text(_l10n.noMissingCheckoutsEmpty,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: TaskTheme.textPrimary)),
          const SizedBox(height: 6),
          Text(
            _l10n.allWorkersValidClockout,
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final totalMissing =
        _entries.fold(0, (s, e) => s + e.missingSessions.length);

    return _statPill(
      icon: PhosphorIconsRegular.signIn,
      color: TaskTheme.overdue,
      value: '$totalMissing',
      label: _l10n.missingCheckoutsTitle,
    );
  }

  Widget _statPill({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: TaskTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  TaskTheme.heading3.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TaskTheme.caption,
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildWorkerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(PhosphorIconsRegular.listBullets,
                size: 18, color: TaskTheme.overdue),
            const SizedBox(width: 8),
            Text(_l10n.detailsByWorkerTitle,
                style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ..._entries.map((entry) => _buildWorkerCard(entry)),
      ],
    );
  }

  Widget _buildWorkerCard(_WorkerMissingEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: TaskTheme.cardShadow,
        border: const Border(
          right: BorderSide(color: Color(0xFFEF4444), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Worker header row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(PhosphorIconsRegular.user,
                      size: 20, color: Color(0xFFEF4444)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(entry.userName, style: TaskTheme.heading3),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(PhosphorIconsRegular.warning,
                          size: 13, color: Color(0xFFDC2626)),
                      const SizedBox(width: 4),
                      Text(
                        '${entry.missingSessions.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 14, endIndent: 14),
          // Missing session dates
          Padding(
            padding:
                const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.missingSessions.map((s) {
                final date =
                    DateFormat('d/M · HH:mm', _localeCode).format(s.clockIn);
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AttendanceCorrectionScreen(
                        userId: entry.userId,
                        userName: entry.userName,
                        highlightClockIn: s.clockIn,
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFFFCA5A5), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(PhosphorIconsRegular.signIn,
                            size: 12, color: Color(0xFFEF4444)),
                        const SizedBox(width: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(PhosphorIconsRegular.arrowRight,
                            size: 10, color: Color(0xFFEF4444)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data class ────────────────────────────────────────────────────────────────

class _WorkerMissingEntry {
  final String userId;
  final String userName;
  final List<AttendanceRecord> missingSessions;

  const _WorkerMissingEntry({
    required this.userId,
    required this.userName,
    required this.missingSessions,
  });
}
