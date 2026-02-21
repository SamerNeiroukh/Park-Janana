import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';
import 'package:park_janana/features/reports/services/report_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class WorkersHoursReport extends StatefulWidget {
  const WorkersHoursReport({super.key});

  @override
  State<WorkersHoursReport> createState() => _WorkersHoursReportState();
}

class _WorkersHoursReportState extends State<WorkersHoursReport> {
  late DateTime _selectedMonth;
  bool _isLoading = true;
  bool _isExporting = false;
  List<AttendanceModel> _records = [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ReportService.getAllWorkersAttendanceByMonth(
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );
      data.sort((a, b) => b.totalHoursWorked.compareTo(a.totalHoursWorked));
      if (mounted) setState(() { _records = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _records = []; _isLoading = false; });
    }
  }

  void _onMonthChanged(DateTime m) {
    setState(() => _selectedMonth = m);
    _load();
  }

  Future<void> _exportPdf() async {
    if (_records.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportWorkersHoursPdf(
        context: context,
        records: _records,
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
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_alt_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('שעות עבודה', style: TaskTheme.heading2),
                ],
              ),
            ),
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_records.isEmpty)
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
            if (!_isLoading && _records.isNotEmpty) _buildBottomBar(),
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
          const Icon(Icons.event_busy_rounded, size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            'אין נתוני נוכחות לחודש זה',
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final totalHours = _records.fold(0.0, (s, r) => s + r.totalHoursWorked);
    final avgHours = _records.isNotEmpty ? totalHours / _records.length : 0.0;

    return Row(
      children: [
        Expanded(
          child: _statPill(
            icon: Icons.group_rounded,
            color: TaskTheme.inProgress,
            value: '${_records.length}',
            label: 'עובדים פעילים',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            icon: Icons.access_time_rounded,
            color: TaskTheme.done,
            value: totalHours.toStringAsFixed(1),
            label: 'סה״כ שעות',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            icon: Icons.trending_up_rounded,
            color: TaskTheme.pending,
            value: avgHours.toStringAsFixed(1),
            label: 'ממוצע לעובד',
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
    final displayed = _records.take(10).toList();
    if (displayed.isEmpty) return const SizedBox.shrink();

    final maxHours = displayed
        .map((r) => r.totalHoursWorked)
        .reduce((a, b) => a > b ? a : b);
    final maxY = (maxHours + 5).ceilToDouble();

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
              const Icon(Icons.bar_chart_rounded, size: 18, color: TaskTheme.primary),
              const SizedBox(width: 8),
              const Text('שעות לפי עובד', style: TaskTheme.heading3),
              if (_records.length > 10) ...[
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
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final name = displayed[group.x].userName;
                        return BarTooltipItem(
                          '$name\n${rod.toY.toStringAsFixed(1)} ש׳',
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
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text('${value.toInt()}',
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
                          final firstName =
                              displayed[idx].userName.split(' ').first;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(firstName,
                                style:
                                    TaskTheme.caption.copyWith(fontSize: 10)),
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
                    horizontalInterval:
                        maxY > 40 ? 10 : maxY > 16 ? 4 : 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: TaskTheme.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(displayed.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: displayed[i].totalHoursWorked,
                          width: displayed.length > 7 ? 18 : 24,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
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
        ..._records.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final rec = entry.value;
          final avg = rec.daysWorked > 0
              ? rec.totalHoursWorked / rec.daysWorked
              : 0.0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TaskTheme.surface,
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              boxShadow: TaskTheme.softShadow,
              border: const Border(
                right: BorderSide(color: Color(0xFF3B82F6), width: 3),
              ),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? const Color(0xFF3B82F6).withOpacity(0.12)
                          : TaskTheme.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: rank <= 3
                              ? const Color(0xFF3B82F6)
                              : TaskTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rec.userName, style: TaskTheme.heading3),
                        const SizedBox(height: 3),
                        Text(
                          '${rec.daysWorked} ימים · ממוצע ${avg.toStringAsFixed(1)} ש׳/יום',
                          style: TaskTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${rec.totalHoursWorked.toStringAsFixed(1)} ש׳',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
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
