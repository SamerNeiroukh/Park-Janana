import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:fl_chart/fl_chart.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/attendance/services/attendance_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class AttendanceSummaryScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const AttendanceSummaryScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<AttendanceSummaryScreen> createState() =>
      _AttendanceSummaryScreenState();
}

class _AttendanceSummaryScreenState extends State<AttendanceSummaryScreen> {
  late DateTime selectedMonth;
  bool isLoading = true;
  AttendanceModel? attendanceData;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() => isLoading = true);
    final data = await AttendanceService.getAttendanceForUserByMonth(
      widget.userId,
      selectedMonth,
    );
    if (mounted) {
      setState(() {
        attendanceData = data;
        isLoading = false;
      });
    }
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() => selectedMonth = newMonth);
    _loadAttendance();
  }

  void _exportToPdf() async {
    if (attendanceData == null) return;
    await PdfExportService.exportAttendancePdf(
      context: context,
      userName: widget.userName,
      profileUrl: widget.profileUrl,
      attendance: attendanceData!,
      month: selectedMonth,
    );
  }

  // Group sessions by day number for the bar chart
  Map<int, double> _getHoursPerDay() {
    if (attendanceData == null) return {};
    final map = <int, double>{};
    for (final session in attendanceData!.sessions) {
      final day = session.clockIn.day;
      map[day] = (map[day] ?? 0) + session.hoursWorked;
    }
    return map;
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
                    child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('דו״ח נוכחות', style: TaskTheme.heading2),
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
            else if (attendanceData == null)
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
                      _buildSessionList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            if (!isLoading && attendanceData != null) _buildBottomBar(),
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
          Icon(Icons.event_busy_rounded, size: 64, color: TaskTheme.textTertiary),
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
    final days = attendanceData!.daysWorked;
    final totalHours = attendanceData!.totalHoursWorked;
    final avgHours = days > 0 ? totalHours / days : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            icon: Icons.calendar_today_rounded,
            color: TaskTheme.inProgress,
            value: '$days',
            label: 'ימים',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.access_time_rounded,
            color: TaskTheme.done,
            value: totalHours.toStringAsFixed(1),
            label: 'שעות',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.trending_up_rounded,
            color: TaskTheme.pending,
            value: avgHours.toStringAsFixed(1),
            label: 'ממוצע/יום',
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

  Widget _buildBarChart() {
    final hoursPerDay = _getHoursPerDay();
    if (hoursPerDay.isEmpty) return const SizedBox.shrink();

    final sortedDays = hoursPerDay.keys.toList()..sort();
    final maxHours = hoursPerDay.values.reduce((a, b) => a > b ? a : b);
    final maxY = (maxHours + 2).ceilToDouble();

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
              Icon(Icons.bar_chart_rounded, size: 18, color: TaskTheme.primary),
              const SizedBox(width: 8),
              Text('שעות עבודה לפי יום', style: TaskTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = sortedDays[group.x.toInt()];
                        return BarTooltipItem(
                          'יום $day\n${rod.toY.toStringAsFixed(1)} שעות',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}',
                            style: TaskTheme.caption.copyWith(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= sortedDays.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${sortedDays[idx]}',
                            style: TaskTheme.caption.copyWith(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 8 ? 2 : 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: TaskTheme.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(sortedDays.length, (i) {
                    final day = sortedDays[i];
                    final hours = hoursPerDay[day]!;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: hours,
                          width: sortedDays.length > 15 ? 8 : 14,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
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

  Widget _buildSessionList() {
    final sessions = attendanceData!.sessions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 18, color: TaskTheme.primary),
            const SizedBox(width: 8),
            Text('פירוט נוכחות', style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ...sessions.map((session) {
          final date = DateFormat('dd/MM/yyyy').format(session.clockIn);
          final dayName = DateFormat('EEEE', 'he').format(session.clockIn);
          final clockIn = DateFormat('HH:mm').format(session.clockIn);
          final clockOut = DateFormat('HH:mm').format(session.clockOut);
          final duration = session.clockOut.difference(session.clockIn);
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TaskTheme.surface,
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              boxShadow: TaskTheme.softShadow,
              border: Border(
                right: BorderSide(
                  color: TaskTheme.done,
                  width: 3,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date row
                  Row(
                    children: [
                      Text(
                        '$dayName, $date',
                        style: TaskTheme.label.copyWith(
                          color: TaskTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: TaskTheme.done.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$hoursש׳ $minutesד׳',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: TaskTheme.done,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Clock in/out row
                  Row(
                    children: [
                      Icon(Icons.login_rounded, size: 16, color: TaskTheme.inProgress),
                      const SizedBox(width: 6),
                      Text(
                        'כניסה: $clockIn',
                        style: TaskTheme.body.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.logout_rounded, size: 16, color: TaskTheme.overdue),
                      const SizedBox(width: 6),
                      Text(
                        'יציאה: $clockOut',
                        style: TaskTheme.body.copyWith(fontSize: 13),
                      ),
                    ],
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
