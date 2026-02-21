import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';
import 'package:park_janana/features/reports/services/report_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class ShiftCoverageReport extends StatefulWidget {
  const ShiftCoverageReport({super.key});

  @override
  State<ShiftCoverageReport> createState() => _ShiftCoverageReportState();
}

class _ShiftCoverageReportState extends State<ShiftCoverageReport> {
  late DateTime _selectedMonth;
  bool _isLoading = true;
  bool _isExporting = false;
  List<DeptShiftStat> _deptStats = [];
  int _totalShifts = 0;

  // Department display order
  static const _deptOrder = [
    'paintball',
    'ropes',
    'carting',
    'water_park',
    'jimbory',
  ];

  static const Map<String, Color> _deptColors = {
    'paintball': Color(0xFF6366F1),
    'ropes': Color(0xFF10B981),
    'carting': Color(0xFFF59E0B),
    'water_park': Color(0xFF3B82F6),
    'jimbory': Color(0xFFEC4899),
  };

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
      if (mounted) setState(() { _deptStats = []; _isLoading = false; });
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final shifts = await ReportService.getAllShiftsByMonth(
      year: _selectedMonth.year,
      month: _selectedMonth.month,
    );

    // Group by department — count only non-cancelled shifts for fill stats
    final Map<String, _DeptAgg> agg = {};
    for (final shift in shifts) {
      final dept = shift.department.isNotEmpty ? shift.department : 'other';
      agg.putIfAbsent(dept, () => _DeptAgg());
      agg[dept]!.shiftCount++;
      if (shift.status != 'cancelled') {
        agg[dept]!.totalCapacity += shift.maxWorkers;
        agg[dept]!.filledSlots += shift.assignedWorkers.length;
      }
    }

    // Build stats ordered by _deptOrder, then alphabetically for any extras
    final ordered = <DeptShiftStat>[];
    for (final dept in _deptOrder) {
      if (agg.containsKey(dept)) {
        final a = agg[dept]!;
        ordered.add(DeptShiftStat(
          department: dept,
          hebrewName: TaskTheme.departmentLabel(dept),
          shiftCount: a.shiftCount,
          totalCapacity: a.totalCapacity,
          filledSlots: a.filledSlots,
        ));
      }
    }
    for (final entry in agg.entries) {
      if (!_deptOrder.contains(entry.key)) {
        ordered.add(DeptShiftStat(
          department: entry.key,
          hebrewName: TaskTheme.departmentLabel(entry.key),
          shiftCount: entry.value.shiftCount,
          totalCapacity: entry.value.totalCapacity,
          filledSlots: entry.value.filledSlots,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _deptStats = ordered;
        _totalShifts = shifts.length;
        _isLoading = false;
      });
    }
  }

  void _onMonthChanged(DateTime m) {
    setState(() => _selectedMonth = m);
    _loadSafe();
  }

  Future<void> _exportPdf() async {
    if (_deptStats.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportShiftCoveragePdf(
        context: context,
        stats: _deptStats,
        totalShifts: _totalShifts,
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
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.domain_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('כיסוי משמרות', style: TaskTheme.heading2),
                ],
              ),
            ),
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_deptStats.isEmpty)
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
                      _buildDeptList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _deptStats.isNotEmpty) _buildBottomBar(),
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
          const Icon(Icons.calendar_month_outlined,
              size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            'אין משמרות לחודש זה',
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final totalCap = _deptStats.fold(0, (s, d) => s + d.totalCapacity);
    final totalFilled = _deptStats.fold(0, (s, d) => s + d.filledSlots);
    final fillRate =
        totalCap > 0 ? (totalFilled / totalCap * 100).round() : 0;

    return Row(
      children: [
        Expanded(
          child: _statPill(
            icon: Icons.calendar_today_rounded,
            color: TaskTheme.inProgress,
            value: '$_totalShifts',
            label: 'סה"כ משמרות',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            icon: Icons.check_circle_rounded,
            color: TaskTheme.done,
            value: '$fillRate%',
            label: 'מילוי משרות',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statPill(
            icon: Icons.store_rounded,
            color: TaskTheme.pending,
            value: '${_deptStats.length}',
            label: 'מחלקות פעילות',
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
    if (_deptStats.isEmpty) return const SizedBox.shrink();

    final maxShifts = _deptStats
        .map((d) => d.shiftCount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final maxY = (maxShifts + 2).ceilToDouble();

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
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 18, color: TaskTheme.done),
              SizedBox(width: 8),
              Text('משמרות לפי מחלקה', style: TaskTheme.heading3),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) {
                        final d = _deptStats[group.x];
                        return BarTooltipItem(
                          '${d.hebrewName}\n${d.shiftCount} משמרות',
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
                        reservedSize: 28,
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
                          if (idx < 0 || idx >= _deptStats.length) {
                            return const SizedBox.shrink();
                          }
                          // Short Hebrew abbreviation
                          final name = _deptStats[idx].hebrewName;
                          final short =
                              name.length > 5 ? name.substring(0, 5) : name;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(short,
                                style: TaskTheme.caption.copyWith(fontSize: 9)),
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
                    horizontalInterval: maxY > 10 ? 5 : 2,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: TaskTheme.border.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(_deptStats.length, (i) {
                    final dept = _deptStats[i].department;
                    final color = _deptColors[dept] ?? TaskTheme.primary;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _deptStats[i].shiftCount.toDouble(),
                          width: _deptStats.length > 4 ? 28 : 36,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          color: color,
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

  Widget _buildDeptList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 18, color: TaskTheme.primary),
            SizedBox(width: 8),
            Text('פירוט מחלקות', style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ..._deptStats.map((d) {
          final color = _deptColors[d.department] ?? TaskTheme.primary;
          final fillRate = d.totalCapacity > 0
              ? (d.filledSlots / d.totalCapacity * 100).round()
              : 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TaskTheme.surface,
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              boxShadow: TaskTheme.softShadow,
              border: Border(right: BorderSide(color: color, width: 3)),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.domain_rounded, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.hebrewName, style: TaskTheme.heading3),
                        const SizedBox(height: 4),
                        Text(
                          '${d.shiftCount} משמרות · ${d.filledSlots}/${d.totalCapacity} מקומות מלאים',
                          style: TaskTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$fillRate%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
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

// ─── Internal accumulator ─────────────────────────────────────────────────────

class _DeptAgg {
  int shiftCount = 0;
  int totalCapacity = 0;
  int filledSlots = 0;
}
