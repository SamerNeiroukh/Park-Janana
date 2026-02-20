import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/reports/services/report_service.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/core/services/firebase_service.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class WorkerShiftReport extends StatefulWidget {
  final String uid;
  final String fullName;
  final String profilePicture;

  const WorkerShiftReport({
    super.key,
    required this.uid,
    required this.fullName,
    required this.profilePicture,
  });

  @override
  State<WorkerShiftReport> createState() => _WorkerShiftReportState();
}

class _WorkerShiftReportState extends State<WorkerShiftReport> {
  final FirebaseService _firebaseService = FirebaseService();
  late DateTime _selectedMonth;
  bool _isLoading = true;
  List<ShiftModel> _shifts = [];
  Map<String, String> _uidToName = {};

  // Track which cards are expanded
  final Set<int> _expandedCards = {};

  static const Map<String, String> _statusTranslations = {
    'active': 'פעילה',
    'cancelled': 'מבוטלת',
    'pending': 'ממתינה',
  };

  static const Map<String, String> _roleTranslations = {
    'worker': 'עובד',
    'shift_manager': 'מנהל משמרת',
    'department_manager': 'מנהל מחלקה',
    'manager': 'מנהל',
    'owner': 'בעלים',
  };

  static const Map<String, String> _decisionTranslations = {
    'accepted': 'מאושר',
    'rejected': 'נדחה',
    'removed': 'הוסר',
    '': 'ממתין',
  };

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    setState(() => _isLoading = true);
    final shifts = await ReportService.getShiftsForWorkerByMonth(
      userId: widget.uid,
      month: _selectedMonth,
    );

    // Pre-fetch all UIDs to fix N+1
    final Set<String> allUids = {};
    for (final shift in shifts) {
      for (final data in shift.assignedWorkerData) {
        if (data['decisionBy'] != null) allUids.add(data['decisionBy']);
        if (data['removedBy'] != null) allUids.add(data['removedBy']);
        if (data['undoBy'] != null) allUids.add(data['undoBy']);
      }
    }

    final Map<String, String> uidToName = {};
    for (final uid in allUids) {
      try {
        final doc = await _firebaseService.getUser(uid);
        final data = doc.data() as Map<String, dynamic>?;
        uidToName[uid] = data?['fullName'] ?? uid;
      } catch (_) {
        uidToName[uid] = uid;
      }
    }

    if (mounted) {
      setState(() {
        _shifts = shifts;
        _uidToName = uidToName;
        _expandedCards.clear();
        _isLoading = false;
      });
    }
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() => _selectedMonth = newMonth);
    _fetchShifts();
  }

  void _exportPdf() async {
    if (_shifts.isEmpty) return;
    await PdfExportService.exportShiftReportPdf(
      context: context,
      userName: widget.fullName,
      profileUrl: widget.profilePicture,
      shifts: _shifts,
      month: _selectedMonth,
      userId: widget.uid,
      uidToNameMap: _uidToName,
    );
  }

  // Get decision stats
  Map<String, int> _getDecisionCounts() {
    final counts = <String, int>{'accepted': 0, 'rejected': 0, 'other': 0};
    for (final shift in _shifts) {
      final userData = _getUserData(shift);
      final decision = userData['decision'] ?? '';
      if (decision == 'accepted') {
        counts['accepted'] = counts['accepted']! + 1;
      } else if (decision == 'rejected') {
        counts['rejected'] = counts['rejected']! + 1;
      } else {
        counts['other'] = counts['other']! + 1;
      }
    }
    return counts;
  }

  Map<String, dynamic> _getUserData(ShiftModel shift) {
    final userDataList = shift.assignedWorkerData
        .where((d) => d['userId'] == widget.uid)
        .toList();
    userDataList.sort((a, b) {
      final Timestamp aTime =
          a['decisionAt'] ?? a['requestedAt'] ?? Timestamp(0, 0);
      final Timestamp bTime =
          b['decisionAt'] ?? b['requestedAt'] ?? Timestamp(0, 0);
      return bTime.compareTo(aTime);
    });
    return userDataList.isNotEmpty
        ? Map<String, dynamic>.from(userDataList.first)
        : {};
  }

  String _resolveName(dynamic uid) =>
      _uidToName[uid] ?? uid?.toString() ?? '---';

  String? _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    }
    return null;
  }

  Color _decisionColor(String decision) {
    switch (decision) {
      case 'accepted':
        return TaskTheme.done;
      case 'rejected':
        return TaskTheme.overdue;
      case 'removed':
        return TaskTheme.pending;
      default:
        return TaskTheme.textTertiary;
    }
  }

  // Department color for left border
  Color _departmentColor(String dept) {
    switch (dept) {
      case 'paintball':
        return const Color(0xFFEF4444);
      case 'ropes':
        return const Color(0xFFF59E0B);
      case 'carting':
        return const Color(0xFF3B82F6);
      case 'water_park':
        return const Color(0xFF06B6D4);
      case 'jimbory':
        return const Color(0xFFA855F7);
      default:
        return TaskTheme.primary;
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
                    child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('דו״ח משמרות', style: TaskTheme.heading2),
                ],
              ),
            ),
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_shifts.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildStatRow(),
                      const SizedBox(height: 16),
                      _buildShiftList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            if (!_isLoading && _shifts.isNotEmpty) _buildBottomBar(),
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
            'אין משמרות לחודש זה',
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow() {
    final counts = _getDecisionCounts();
    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            icon: Icons.schedule_rounded,
            color: TaskTheme.inProgress,
            value: '${_shifts.length}',
            label: 'סה״כ',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.check_circle_rounded,
            color: TaskTheme.done,
            value: '${counts['accepted']}',
            label: 'אושרו',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.cancel_rounded,
            color: TaskTheme.overdue,
            value: '${counts['rejected']! + counts['other']!}',
            label: 'נדחו/אחר',
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

  Widget _buildShiftList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt_rounded, size: 18, color: TaskTheme.primary),
            const SizedBox(width: 8),
            Text('פירוט משמרות', style: TaskTheme.heading3),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(_shifts.length, (i) => _buildShiftCard(i)),
      ],
    );
  }

  Widget _buildShiftCard(int index) {
    final shift = _shifts[index];
    final userData = _getUserData(shift);
    final decision = userData['decision'] ?? '';
    final decColor = _decisionColor(decision);
    final hebrewDecision = _decisionTranslations[decision] ?? decision;
    final shiftStatus = _statusTranslations[shift.status] ?? shift.status;
    final deptColor = _departmentColor(shift.department);
    final isExpanded = _expandedCards.contains(index);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        boxShadow: TaskTheme.softShadow,
        border: Border(
          right: BorderSide(color: deptColor, width: 3),
        ),
      ),
      child: Column(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + time row
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: TaskTheme.textTertiary),
                    const SizedBox(width: 6),
                    Text(
                      shift.date,
                      style: TaskTheme.label
                          .copyWith(color: TaskTheme.textPrimary),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time_rounded,
                        size: 14, color: TaskTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      '${shift.startTime} - ${shift.endTime}',
                      style: TaskTheme.body.copyWith(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Department + status + decision chips
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildChip(
                      TaskTheme.departmentLabel(shift.department),
                      deptColor,
                    ),
                    _buildChip(shiftStatus, TaskTheme.inProgress),
                    _buildChip(hebrewDecision, decColor),
                  ],
                ),
              ],
            ),
          ),
          // Expand/collapse button
          if (userData.isNotEmpty)
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedCards.remove(index);
                  } else {
                    _expandedCards.add(index);
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: TaskTheme.background,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(
                        isExpanded ? 0 : TaskTheme.radiusM),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isExpanded ? 'הסתר פרטים' : 'הצג פרטים',
                      style: TaskTheme.caption.copyWith(
                        color: TaskTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: TaskTheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          // Expanded details
          if (isExpanded && userData.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              decoration: BoxDecoration(
                color: TaskTheme.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(TaskTheme.radiusM),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: TaskTheme.divider),
                  const SizedBox(height: 10),
                  if (userData['decisionBy'] != null)
                    _buildDetailRow(
                        'אושר ע״י', _resolveName(userData['decisionBy'])),
                  if (userData['decisionAt'] != null)
                    _buildDetailRow(
                        'בתאריך', _formatTimestamp(userData['decisionAt'])),
                  if (userData['roleAtAssignment'] != null)
                    _buildDetailRow(
                      'תפקיד בעת השיבוץ',
                      _roleTranslations[userData['roleAtAssignment']] ??
                          userData['roleAtAssignment'],
                    ),
                  if (userData['requestedAt'] != null)
                    _buildDetailRow(
                        'זמן בקשה', _formatTimestamp(userData['requestedAt'])),
                  if (userData['removedBy'] != null)
                    _buildDetailRow(
                        'הוסר ע״י', _resolveName(userData['removedBy'])),
                  if (userData['removedAt'] != null)
                    _buildDetailRow(
                        'זמן הסרה', _formatTimestamp(userData['removedAt'])),
                  if (userData['undoBy'] != null)
                    _buildDetailRow(
                        'בוטל ע״י', _resolveName(userData['undoBy'])),
                  if (userData['undoAt'] != null)
                    _buildDetailRow(
                        'זמן ביטול', _formatTimestamp(userData['undoAt'])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TaskTheme.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: TaskTheme.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TaskTheme.caption.copyWith(
                color: TaskTheme.textPrimary,
              ),
            ),
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
              onTap: _exportPdf,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
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
