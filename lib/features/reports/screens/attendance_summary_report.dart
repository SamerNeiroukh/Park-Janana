import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
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
  late AppLocalizations _l10n;
  late String _localeCode;

  // Date range mode
  bool _isRangeMode = false;
  DateTimeRange? _dateRange;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadAttendance();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
    _localeCode = Localizations.localeOf(context).languageCode;
  }

  Future<void> _loadAttendance() async {
    setState(() => isLoading = true);
    final AttendanceModel? data;
    if (_isRangeMode && _dateRange != null) {
      data = await AttendanceService.getAttendanceForUserByDateRange(
        widget.userId,
        _dateRange!.start,
        _dateRange!.end,
      );
    } else {
      data = await AttendanceService.getAttendanceForUserByMonth(
        widget.userId,
        selectedMonth,
      );
    }
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

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      locale: const Locale('he'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF3B82F6),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
      _loadAttendance();
    }
  }

  void _toggleRangeMode() {
    setState(() {
      _isRangeMode = !_isRangeMode;
      if (!_isRangeMode) _dateRange = null;
    });
    _loadAttendance();
  }

  Future<void> _exportToPdf() async {
    if (attendanceData == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportAttendancePdf(
        context: context,
        userName: widget.userName,
        profileUrl: widget.profileUrl,
        attendance: attendanceData!,
        month: selectedMonth,
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(PhosphorIconsRegular.clock, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(_l10n.attendanceReportTitle, style: TaskTheme.heading2),
                  const Spacer(),
                  // Toggle between month picker and custom date range
                  GestureDetector(
                    onTap: _toggleRangeMode,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isRangeMode
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            PhosphorIconsRegular.calendarDots,
                            size: 16,
                            color: _isRangeMode ? Colors.white : const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _l10n.dateRangeButton,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _isRangeMode ? Colors.white : const Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isRangeMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: GestureDetector(
                  onTap: _pickDateRange,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsRegular.calendarBlank,
                            size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          _dateRange == null
                              ? _l10n.selectDateRange
                              : '${_dateRange!.start.day}/${_dateRange!.start.month}/${_dateRange!.start.year}  —  ${_dateRange!.end.day}/${_dateRange!.end.month}/${_dateRange!.end.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _dateRange == null
                                ? Colors.grey.shade500
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        const Spacer(),
                        Icon(PhosphorIconsRegular.calendarPlus,
                            size: 16, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              )
            else
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
                child: RefreshIndicator(
                  color: TaskTheme.inProgress,
                  onRefresh: _loadAttendance,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
              ),
            if (!isLoading && attendanceData != null) _buildBottomBar(),
          ],
        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(PhosphorIconsRegular.calendarX, size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            _l10n.noAttendanceDataMonth,
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
            icon: PhosphorIconsRegular.calendarBlank,
            color: TaskTheme.inProgress,
            value: '$days',
            label: _l10n.daysLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: PhosphorIconsRegular.clock,
            color: TaskTheme.done,
            value: totalHours.toStringAsFixed(1),
            label: _l10n.hoursLabel,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: PhosphorIconsRegular.trendUp,
            color: TaskTheme.pending,
            value: avgHours.toStringAsFixed(1),
            label: _l10n.averagePerDayLabel,
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
              color: color.withValues(alpha: 0.1),
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
              const Icon(PhosphorIconsRegular.chartBar, size: 18, color: TaskTheme.primary),
              const SizedBox(width: 8),
              Text(_l10n.hoursPerDayChartTitle, style: TaskTheme.heading3),
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
                          _l10n.chartTooltipDayHours(day, rod.toY.toStringAsFixed(1)),
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
                      color: TaskTheme.border.withValues(alpha: 0.5),
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
            const Icon(PhosphorIconsRegular.listBullets, size: 18, color: TaskTheme.primary),
            const SizedBox(width: 8),
            Text(_l10n.attendanceDetailsTitle, style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ...sessions.map((session) {
          final date = DateFormat('dd/MM/yyyy').format(session.clockIn);
          final dayName = DateFormat('EEEE', _localeCode).format(session.clockIn);
          final clockIn = DateFormat('HH:mm').format(session.clockIn);
          final clockOut = DateFormat('HH:mm').format(session.clockOut);
          final duration = session.clockOut.difference(session.clockIn);
          final hours = duration.inHours;
          final minutes = duration.inMinutes.remainder(60);
          final isMissed = session.hoursWorked >= 16;
          const missedColor = Color(0xFFF97316);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TaskTheme.surface,
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              boxShadow: TaskTheme.softShadow,
              border: Border(
                right: BorderSide(
                  color: isMissed ? missedColor : TaskTheme.done,
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
                      if (isMissed)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: missedColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsRegular.prohibit, size: 11, color: missedColor),
                              const SizedBox(width: 4),
                              Text(
                                _l10n.missingClockOutLabel,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: missedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: (isMissed ? missedColor : TaskTheme.done).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _l10n.durationHoursMinutes(hours, minutes),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isMissed ? missedColor : TaskTheme.done,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Clock in/out row
                  Row(
                    children: [
                      const Icon(PhosphorIconsRegular.signIn, size: 16, color: TaskTheme.inProgress),
                      const SizedBox(width: 6),
                      Text(
                        _l10n.clockInPrefix(clockIn),
                        style: TaskTheme.body.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 20),
                      const Icon(PhosphorIconsRegular.signOut, size: 16, color: TaskTheme.overdue),
                      const SizedBox(width: 6),
                      Text(
                        _l10n.clockOutPrefix(clockOut),
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
              onTap: _isExporting ? null : _exportToPdf,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isExporting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      const Icon(PhosphorIconsRegular.filePdf,
                          color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _isExporting ? _l10n.exportingLabel : _l10n.exportPdfButton,
                      style: const TextStyle(
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
