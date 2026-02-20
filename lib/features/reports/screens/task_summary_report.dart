import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class TaskSummaryReport extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const TaskSummaryReport({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<TaskSummaryReport> createState() => _TaskSummaryReportState();
}

class _TaskSummaryReportState extends State<TaskSummaryReport> {
  late DateTime selectedMonth;
  bool isLoading = true;
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    final fetched = await TaskService.getTasksForUserByMonth(
      widget.userId,
      selectedMonth,
    );
    if (mounted) {
      setState(() {
        tasks = fetched;
        isLoading = false;
      });
    }
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() => selectedMonth = newMonth);
    _loadTasks();
  }

  void _exportToPdf() async {
    if (tasks.isEmpty) return;
    await PdfExportService.exportTaskReportPdf(
      context: context,
      userName: widget.userName,
      profileUrl: widget.profileUrl,
      tasks: tasks,
      month: selectedMonth,
      userId: widget.userId,
    );
  }

  // Count tasks by worker-specific status
  Map<String, int> _getStatusCounts() {
    final counts = <String, int>{'pending': 0, 'in_progress': 0, 'done': 0};
    for (final task in tasks) {
      final progress = task.workerProgress[widget.userId];
      final status = progress?['status'] ?? 'pending';
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    }
    return '---';
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
                    child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('דו״ח משימות', style: TaskTheme.heading2),
                ],
              ),
            ),
            MonthSelector(
              selectedMonth: selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (tasks.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatRow(),
                      const SizedBox(height: 16),
                      _buildPieChart(),
                      const SizedBox(height: 16),
                      _buildTaskList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            if (!isLoading && tasks.isNotEmpty) _buildBottomBar(),
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
          Icon(Icons.assignment_outlined, size: 64, color: TaskTheme.textTertiary),
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
    final counts = _getStatusCounts();
    final completed = counts['done'] ?? 0;
    final total = tasks.length;
    final rate = total > 0 ? (completed / total * 100) : 0.0;

    Color rateColor;
    if (rate >= 75) {
      rateColor = TaskTheme.done;
    } else if (rate >= 40) {
      rateColor = TaskTheme.pending;
    } else {
      rateColor = TaskTheme.overdue;
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            icon: Icons.assignment_rounded,
            color: TaskTheme.inProgress,
            value: '$total',
            label: 'סה״כ',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.check_circle_rounded,
            color: TaskTheme.done,
            value: '$completed',
            label: 'הושלמו',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.percent_rounded,
            color: rateColor,
            value: '${rate.toInt()}%',
            label: 'ביצוע',
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
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
          Text(
            value,
            style: TaskTheme.heading3.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(label, style: TaskTheme.caption),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final counts = _getStatusCounts();
    final pendingCount = counts['pending'] ?? 0;
    final inProgressCount = counts['in_progress'] ?? 0;
    final doneCount = counts['done'] ?? 0;
    final total = tasks.length;
    final completionPct = total > 0 ? (doneCount / total * 100).toInt() : 0;

    // Don't show chart if no tasks
    if (total == 0) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    if (pendingCount > 0) {
      sections.add(PieChartSectionData(
        value: pendingCount.toDouble(),
        color: TaskTheme.pending,
        radius: 24,
        showTitle: false,
      ));
    }
    if (inProgressCount > 0) {
      sections.add(PieChartSectionData(
        value: inProgressCount.toDouble(),
        color: TaskTheme.inProgress,
        radius: 24,
        showTitle: false,
      ));
    }
    if (doneCount > 0) {
      sections.add(PieChartSectionData(
        value: doneCount.toDouble(),
        color: TaskTheme.done,
        radius: 24,
        showTitle: false,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: TaskTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded, size: 18, color: TaskTheme.primary),
              const SizedBox(width: 8),
              Text('התפלגות סטטוס', style: TaskTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 50,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completionPct%',
                      style: TaskTheme.heading1.copyWith(
                        fontWeight: FontWeight.w800,
                        color: TaskTheme.done,
                      ),
                    ),
                    Text('ביצוע', style: TaskTheme.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('ממתין', pendingCount, TaskTheme.pending),
              _buildLegendItem('בביצוע', inProgressCount, TaskTheme.inProgress),
              _buildLegendItem('הושלם', doneCount, TaskTheme.done),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ($count)',
          style: TaskTheme.caption.copyWith(
            color: TaskTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 18, color: TaskTheme.primary),
            const SizedBox(width: 8),
            Text('פירוט משימות', style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ...tasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final entry = task.workerProgress[widget.userId] ?? {};
    final workerStatus = entry['status'] ?? 'pending';
    final priorityColor = TaskTheme.priorityColor(task.priority);
    final statusColor = TaskTheme.statusColor(workerStatus);
    final dueDate = task.dueDate.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        boxShadow: TaskTheme.softShadow,
        border: Border(
          right: BorderSide(color: priorityColor, width: 3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + status row
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TaskTheme.label.copyWith(
                      color: TaskTheme.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    TaskTheme.statusLabel(workerStatus),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                task.description,
                style: TaskTheme.body.copyWith(fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            // Due date
            Row(
              children: [
                Icon(Icons.event_rounded, size: 14, color: TaskTheme.textTertiary),
                const SizedBox(width: 4),
                Text(
                  'יעד: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                  style: TaskTheme.caption,
                ),
              ],
            ),
            // Timeline dots
            if (entry.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: TaskTheme.divider),
              const SizedBox(height: 10),
              _buildTimelineRow(
                'הוגשה',
                _formatTimestamp(entry['submittedAt']),
                TaskTheme.textTertiary,
              ),
              if (entry['startedAt'] != null)
                _buildTimelineRow(
                  'התחילה',
                  _formatTimestamp(entry['startedAt']),
                  TaskTheme.inProgress,
                ),
              if (entry['endedAt'] != null)
                _buildTimelineRow(
                  'הסתיימה',
                  _formatTimestamp(entry['endedAt']),
                  TaskTheme.done,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineRow(String label, String value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TaskTheme.caption.copyWith(fontSize: 12),
          ),
        ],
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
              onTap: _exportToPdf,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ייצוא PDF',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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
