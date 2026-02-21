import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';
import 'package:park_janana/features/reports/services/report_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class TaskDistributionReport extends StatefulWidget {
  const TaskDistributionReport({super.key});

  @override
  State<TaskDistributionReport> createState() => _TaskDistributionReportState();
}

class _TaskDistributionReportState extends State<TaskDistributionReport> {
  late DateTime _selectedMonth;
  bool _isLoading = true;
  bool _isExporting = false;
  List<WorkerTaskStat> _stats = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _loadSafe();
  }

  Future<void> _loadSafe() async {
    try {
      await _load();
    } catch (e) {
      if (mounted) setState(() { _stats = []; _isLoading = false; });
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final tasks = await ReportService.getAllTasksByMonth(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    // Collect all unique worker UIDs across all tasks
    final allUids = <String>{};
    for (final task in tasks) {
      allUids.addAll(task.assignedTo);
      allUids.addAll(task.workerProgress.keys);
    }

    // Batch-fetch names from Firestore
    final Map<String, String> uidToName = {};
    final uidList = allUids.toList();
    for (var i = 0; i < uidList.length; i += 10) {
      final batch = uidList.sublist(
          i, i + 10 > uidList.length ? uidList.length : i + 10);
      final docs = await Future.wait(
        batch.map((uid) => FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get()),
      );
      for (final doc in docs) {
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          uidToName[doc.id] =
              data['fullName'] ?? data['name'] ?? doc.id;
        }
      }
    }

    // Aggregate per worker
    final Map<String, _WorkerCounts> counts = {};
    for (final task in tasks) {
      for (final uid in task.assignedTo) {
        counts.putIfAbsent(uid, () => _WorkerCounts());
        final progress = task.workerProgress[uid];
        final status = progress?['status'] as String? ?? 'pending';
        switch (status) {
          case 'done':
            counts[uid]!.done++;
          case 'in_progress':
            counts[uid]!.inProgress++;
          default:
            counts[uid]!.pending++;
        }
      }
    }

    final stats = counts.entries.map((e) {
      final total = e.value.done + e.value.inProgress + e.value.pending;
      return WorkerTaskStat(
        uid: e.key,
        name: uidToName[e.key] ?? e.key,
        total: total,
        done: e.value.done,
        inProgress: e.value.inProgress,
        pending: e.value.pending,
      );
    }).toList();

    // Sort by completion rate desc, then total desc
    stats.sort((a, b) {
      final rateA = a.total > 0 ? a.done / a.total : 0.0;
      final rateB = b.total > 0 ? b.done / b.total : 0.0;
      final cmp = rateB.compareTo(rateA);
      return cmp != 0 ? cmp : b.total.compareTo(a.total);
    });

    if (mounted) setState(() { _stats = stats; _isLoading = false; });
  }


  void _onMonthChanged(DateTime m) {
    setState(() => _selectedMonth = m);
    _loadSafe();
  }

  Future<void> _exportPdf() async {
    if (_stats.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportTaskDistributionPdf(
        context: context,
        stats: _stats,
        month: _selectedMonth,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('התפלגות משימות', style: TaskTheme.heading2),
                ],
              ),
            ),
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_stats.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatRow(),
                      const SizedBox(height: 16),
                      _buildBarChart(),
                      const SizedBox(height: 20),
                      _buildWorkerList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _stats.isNotEmpty) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.assignment_outlined,
              size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            'אין משימות לחודש זה',
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final totalTasks = _stats.fold(0, (s, r) => s + r.total);
    final totalDone = _stats.fold(0, (s, r) => s + r.done);
    final overallRate =
        totalTasks > 0 ? (totalDone / totalTasks * 100).round() : 0;
    final rateColor = overallRate >= 70
        ? TaskTheme.done
        : overallRate >= 40
            ? TaskTheme.pending
            : TaskTheme.overdue;

    return Row(
      children: [
        Expanded(
          child: _statPill(
            icon: Icons.task_alt_rounded,
            color: TaskTheme.inProgress,
            value: '$totalTasks',
            label: 'סה"כ משימות',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            icon: Icons.people_rounded,
            color: TaskTheme.done,
            value: '${_stats.length}',
            label: 'עובדים עם משימות',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            icon: Icons.percent_rounded,
            color: rateColor,
            value: '$overallRate%',
            label: 'שיעור השלמה',
          ),
        ),
      ],
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
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TaskTheme.heading3.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TaskTheme.caption,
              textAlign: TextAlign.center,
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final displayed = _stats.take(10).toList();
    if (displayed.isEmpty) return const SizedBox.shrink();

    return Container(
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
              const Icon(Icons.bar_chart_rounded,
                  size: 18, color: TaskTheme.pending),
              const SizedBox(width: 8),
              const Text('שיעור השלמה לפי עובד', style: TaskTheme.heading3),
              if (_stats.length > 10) ...[
                const Spacer(),
                const Text('(10 מובילים)', style: TaskTheme.caption),
              ],
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final s = displayed[group.x];
                        return BarTooltipItem(
                          '${s.name.split(' ').first}\n${rod.toY.round()}%',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text('${value.toInt()}%',
                              style: TaskTheme.caption.copyWith(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= displayed.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              displayed[idx].name.split(' ').first,
                              style: TaskTheme.caption.copyWith(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: TaskTheme.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(displayed.length, (i) {
                    final s = displayed[i];
                    final rate =
                        s.total > 0 ? s.done / s.total * 100 : 0.0;
                    final barColor = rate >= 70
                        ? TaskTheme.done
                        : rate >= 40
                            ? TaskTheme.pending
                            : TaskTheme.overdue;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: rate,
                          width: displayed.length > 7 ? 18 : 24,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          color: barColor,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 18, color: TaskTheme.primary),
            SizedBox(width: 8),
            Text('פירוט עובדים', style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ..._stats.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final s = entry.value;
          final rate = s.total > 0 ? (s.done / s.total * 100).round() : 0;
          final borderColor = rate >= 70
              ? TaskTheme.done
              : rate >= 40
                  ? TaskTheme.pending
                  : TaskTheme.overdue;
          final rateColor = borderColor;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TaskTheme.surface,
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              boxShadow: TaskTheme.softShadow,
              border: Border(right: BorderSide(color: borderColor, width: 3)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? TaskTheme.done.withOpacity(0.12)
                          : TaskTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text('$rank',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: rank <= 3
                                ? TaskTheme.done
                                : TaskTheme.textSecondary,
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: TaskTheme.heading3),
                        const SizedBox(height: 6),
                        // Status chips row
                        Row(
                          children: [
                            _chip('${s.done}', 'הושלם', TaskTheme.done),
                            const SizedBox(width: 6),
                            _chip('${s.inProgress}', 'בביצוע',
                                TaskTheme.inProgress),
                            const SizedBox(width: 6),
                            _chip(
                                '${s.pending}', 'ממתין', TaskTheme.pending),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: rateColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$rate%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: rateColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _chip(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: TaskTheme.topBarShadow,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TaskTheme.radiusM),
            gradient: const LinearGradient(
              colors: [TaskTheme.primary, Color(0xFF5B8DEF)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            boxShadow: TaskTheme.buttonShadow(TaskTheme.primary),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(TaskTheme.radiusM),
            child: InkWell(
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              onTap: _isExporting ? null : _exportPdf,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _isExporting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ייצוא PDF',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Internal accumulator ─────────────────────────────────────────────────────

class _WorkerCounts {
  int done = 0;
  int inProgress = 0;
  int pending = 0;
}
