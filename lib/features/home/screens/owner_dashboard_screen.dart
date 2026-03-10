import 'dart:math' as math;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/reports/services/report_service.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/features/workers/screens/manage_workers_screen.dart';
import 'package:park_janana/features/workers/screens/review_worker_screen.dart';
import 'package:park_janana/features/shifts/screens/manager_weekly_schedule_screen.dart';
import 'package:park_janana/features/shifts/screens/create_shift_screen.dart';
import 'package:park_janana/features/tasks/screens/all_tasks_screen.dart';
import 'package:park_janana/features/tasks/screens/create_task_flow_screen.dart';
import 'package:park_janana/features/newsfeed/widgets/create_post_dialog.dart';
import 'package:park_janana/features/reports/screens/workers_hours_report.dart';


// ─── Data models ────────────────────────────────────────────────────────────

class _TopWorker {
  final String name;
  final double hours;
  final int days;
  const _TopWorker({required this.name, required this.hours, required this.days});
}

class _ActiveWorker {
  final String userId;
  final String name;
  final String? profilePictureUrl;
  final String profilePicturePath;
  final DateTime clockIn;
  const _ActiveWorker({
    required this.userId,
    required this.name,
    required this.profilePictureUrl,
    required this.profilePicturePath,
    required this.clockIn,
  });

  Duration get elapsed => DateTime.now().difference(clockIn);
}

class _KpiData {
  final int workersCount;
  final int managersCount;
  final int pendingApproval;
  final int shiftsToday;
  final int shiftsThisWeek;
  final double avgShiftFill; // 0.0–1.0
  final int openTasks;
  final int highPriorityTasks;
  final int doneTasks;
  final double totalHoursMonth;
  final int clockedInToday;
  final int understaffedShiftsToday;
  final List<_TopWorker> topWorkers;
  final List<_ActiveWorker> activeNow;

  const _KpiData({
    required this.workersCount,
    required this.managersCount,
    required this.pendingApproval,
    required this.shiftsToday,
    required this.shiftsThisWeek,
    required this.avgShiftFill,
    required this.openTasks,
    required this.highPriorityTasks,
    required this.doneTasks,
    required this.totalHoursMonth,
    required this.clockedInToday,
    required this.understaffedShiftsToday,
    required this.topWorkers,
    required this.activeNow,
  });

  int get totalStaff => workersCount + managersCount;
}

// ─── Screen ────────────────────────────────────────────────────────────────

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  _KpiData? _kpi;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadKpis();
  }

  Future<void> _loadKpis() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final today = DateFormat('dd/MM/yyyy').format(now);

      // Build week date strings (today ± so we cover Mon–Sun)
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekDates = List.generate(
        7,
        (i) => DateFormat('dd/MM/yyyy').format(weekStart.add(Duration(days: i))),
      );

      // ── Parallel phase ────────────────────────────────────────────────
      final db = FirebaseFirestore.instance;

      final results = await Future.wait<QuerySnapshot<Map<String, dynamic>>>([
        // [0] Approved workers
        db
            .collection(AppConstants.usersCollection)
            .where('approved', isEqualTo: true)
            .where('role', isEqualTo: 'worker')
            .get(),
        // [1] Approved managers
        db
            .collection(AppConstants.usersCollection)
            .where('approved', isEqualTo: true)
            .where('role', isEqualTo: 'manager')
            .get(),
        // [2] Not-yet-approved users (rejected field may be absent on new registrations)
        db
            .collection(AppConstants.usersCollection)
            .where('approved', isEqualTo: false)
            .get(),
        // [3] Open tasks
        db
            .collection(AppConstants.tasksCollection)
            .where('status', whereIn: ['pending', 'in_progress'])
            .get(),
        // [4] Shifts today
        db
            .collection(AppConstants.shiftsCollection)
            .where('date', isEqualTo: today)
            .get(),
      ]);

      final workersSnap = results[0];
      final managersSnap = results[1];
      final pendingSnap = results[2];
      final openTasksSnap = results[3];
      final todayShiftsSnap = results[4];

      // ── Week shifts (may need batching) ───────────────────────────────
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> weekShiftDocs = [];
      for (var i = 0; i < weekDates.length; i += 30) {
        final batch = weekDates.sublist(
            i, i + 30 > weekDates.length ? weekDates.length : i + 30);
        final snap = await db
            .collection(AppConstants.shiftsCollection)
            .where('date', whereIn: batch)
            .get();
        weekShiftDocs.addAll(snap.docs);
      }

      // ── Done tasks count ──────────────────────────────────────────────
      final doneSnap = await db
          .collection(AppConstants.tasksCollection)
          .where('status', isEqualTo: 'done')
          .get();

      // ── Sequential: attendance (heavier) ─────────────────────────────
      final attendance = await ReportService.getAllWorkersAttendanceByMonth(
        year: now.year,
        month: now.month,
      );

      // ── Compute KPIs ──────────────────────────────────────────────────
      // Avg shift fill: assigned / maxWorkers per shift
      double totalFill = 0;
      int shiftCount = 0;
      for (final doc in weekShiftDocs) {
        final data = doc.data();
        final max = (data['maxWorkers'] as num?)?.toInt() ?? 0;
        final assigned =
            (data['assignedWorkerData'] as List?)?.length ?? 0;
        if (max > 0) {
          totalFill += assigned / max;
          shiftCount++;
        }
      }
      final avgFill = shiftCount > 0 ? totalFill / shiftCount : 0.0;

      // High priority open tasks
      final highPriority = openTasksSnap.docs
          .where((d) => d.data()['priority'] == 'high')
          .length;

      // Total hours this month
      final totalHours = attendance.fold<double>(
        0,
        (acc, a) => acc + a.totalHoursWorked,
      );

      // Clocked in today: workers with at least one session starting on today's date
      int clockedInToday = 0;
      for (final record in attendance) {
        final hasSessionToday = record.sessions.any(
          (s) =>
              s.clockIn.year == now.year &&
              s.clockIn.month == now.month &&
              s.clockIn.day == now.day,
        );
        if (hasSessionToday) clockedInToday++;
      }

      // Understaffed shifts today: shifts with fill < 50%
      int understaffedShiftsToday = 0;
      for (final doc in todayShiftsSnap.docs) {
        final data = doc.data();
        final max = (data['maxWorkers'] as num?)?.toInt() ?? 0;
        final assigned = (data['assignedWorkerData'] as List?)?.length ?? 0;
        if (max > 0 && assigned / max < 0.5) understaffedShiftsToday++;
      }

      // Build uid → profilePictureUrl / profilePicturePath maps from already-fetched snapshots
      final allUserDocs = [...workersSnap.docs, ...managersSnap.docs];
      final profileUrlMap = <String, String?>{
        for (final doc in allUserDocs)
          doc.id: doc.data()['profile_picture'] as String?,
      };
      final profilePathMap = <String, String>{
        for (final doc in allUserDocs)
          doc.id: (doc.data()['profile_picture_path'] as String?)
              ?? 'profile_pictures/${doc.id}/profile.jpg',
      };

      // Workers currently clocked in: last session today has clockIn == clockOut (no clockOut yet)
      final List<_ActiveWorker> activeNow = [];
      for (final record in attendance) {
        final todaySessions = record.sessions.where(
          (s) =>
              s.clockIn.year == now.year &&
              s.clockIn.month == now.month &&
              s.clockIn.day == now.day,
        ).toList();
        if (todaySessions.isNotEmpty) {
          final last = todaySessions.last;
          // An open session is stored with clockOut == clockIn as a placeholder.
          // isAtSameMomentAs is the correct Dart API for DateTime equality.
          // The 24h guard protects against stale placeholder sessions from crashes/bugs.
          final isOpen = last.clockIn.isAtSameMomentAs(last.clockOut) &&
              now.difference(last.clockIn).inHours < 24;
          if (isOpen) {
            activeNow.add(_ActiveWorker(
              userId: record.userId,
              name: record.userName,
              profilePictureUrl: profileUrlMap[record.userId],
              profilePicturePath: profilePathMap[record.userId]
                  ?? 'profile_pictures/${record.userId}/profile.jpg',
              clockIn: last.clockIn,
            ));
          }
        }
      }
      activeNow.sort((a, b) => a.clockIn.compareTo(b.clockIn));

      // Top workers this month (top 3 by hours)
      final sorted = [...attendance]
        ..sort((a, b) => b.totalHoursWorked.compareTo(a.totalHoursWorked));
      final topWorkers = sorted
          .take(3)
          .map((a) => _TopWorker(
                name: a.userName,
                hours: a.totalHoursWorked,
                days: a.daysWorked,
              ))
          .toList();

      setState(() {
        _kpi = _KpiData(
          workersCount: workersSnap.docs.length,
          managersCount: managersSnap.docs.length,
          // Exclude rejected users (field may be absent on fresh registrations)
          pendingApproval: pendingSnap.docs
              .where((d) => d.data()['rejected'] != true)
              .length,
          shiftsToday: todayShiftsSnap.docs.length,
          shiftsThisWeek: weekShiftDocs.length,
          avgShiftFill: avgFill.clamp(0.0, 1.0),
          openTasks: openTasksSnap.docs.length,
          highPriorityTasks: highPriority,
          doneTasks: doneSnap.docs.length,
          totalHoursMonth: totalHours,
          clockedInToday: clockedInToday,
          understaffedShiftsToday: understaffedShiftsToday,
          topWorkers: topWorkers,
          activeNow: activeNow,
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('OwnerDashboard load error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _go(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final ownerName = userProvider.currentUser?.fullName ?? '';
    final currentUser = userProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FC),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError()
                      : RefreshIndicator(
                          onRefresh: _loadKpis,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildWelcomeCard(ownerName),
                                if (_kpi!.pendingApproval > 0) ...[
                                  const SizedBox(height: 12),
                                  _buildPendingAlert(),
                                ],
                                if (_kpi!.understaffedShiftsToday > 0) ...[
                                  const SizedBox(height: 12),
                                  _buildUnderstaffedAlert(),
                                ],
                                const SizedBox(height: 16),
                                _buildStatPills(),
                                const SizedBox(height: 12),
                                if (currentUser != null)
                                  _buildQuickActions(currentUser),
                                const SizedBox(height: 16),
                                _buildWorkforceCard(),
                                const SizedBox(height: 12),
                                _buildActiveWorkersCard(),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildShiftsCard()),
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildTasksCard()),
                                  ],
                                ),
                                if (_kpi!.topWorkers.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  _buildTopWorkers(),
                                ],
                                const SizedBox(height: 12),
                                _buildHoursCard(),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              'שגיאה בטעינת הנתונים',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadKpis,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('נסה שוב'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Welcome card ─────────────────────────────────────────────────────────

  Widget _buildWelcomeCard(String ownerName) {
    final now = DateTime.now();
    final dateStr =
        DateFormat('EEEE, d בMMMM yyyy', 'he').format(now);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED), Color(0xFF6D28D9)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.dashboard_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'לוח בקרה — בעלים',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'שלום, $ownerName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded,
                    color: Colors.white70, size: 14),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pending approval alert ────────────────────────────────────────────────

  Widget _buildPendingAlert() {
    return GestureDetector(
      onTap: () => _go(const ManageWorkersScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_add_alt_1_rounded,
                  color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_kpi!.pendingApproval} עובדים ממתינים לאישור',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const Text(
                    'לחץ לניהול עובדים',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFD97706), size: 22),
          ],
        ),
      ),
    );
  }

  // ── Understaffed shifts alert ─────────────────────────────────────────────

  Widget _buildUnderstaffedAlert() {
    return GestureDetector(
      onTap: () => _go(const ManagerWeeklyScheduleScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_kpi!.understaffedShiftsToday} משמרות היום חסרות עובדים',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  const Text(
                    'לחץ לסידור שבועי',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFDC2626), size: 22),
          ],
        ),
      ),
    );
  }

  // ── Quick stat pills (4 across) ───────────────────────────────────────────

  Widget _buildStatPills() {
    final pills = [
      _StatPill(
        value: '${_kpi!.totalStaff}',
        label: 'צוות כולל',
        icon: Icons.groups_rounded,
        color: const Color(0xFF7C3AED),
      ),
      _StatPill(
        value: _kpi!.totalHoursMonth.toStringAsFixed(0),
        label: 'שעות החודש',
        icon: Icons.access_time_filled_rounded,
        color: const Color(0xFF0EA5E9),
      ),
      _StatPill(
        value: '${_kpi!.openTasks}',
        label: 'משימות פתוחות',
        icon: Icons.assignment_rounded,
        color: const Color(0xFF8B5CF6),
      ),
      _StatPill(
        value: '${_kpi!.clockedInToday}',
        label: 'נוכחים היום',
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFF10B981),
      ),
    ];

    return Row(
      children: <Widget>[
        Expanded(child: _buildStatPillCard(pills[0])),
        const SizedBox(width: 8),
        Expanded(child: _buildStatPillCard(pills[1])),
        const SizedBox(width: 8),
        Expanded(child: _buildStatPillCard(pills[2])),
        const SizedBox(width: 8),
        Expanded(child: _buildStatPillCard(pills[3])),
      ],
    );
  }

  Widget _buildStatPillCard(_StatPill p) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(p.icon, color: p.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            p.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: p.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            p.label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  // ── Quick Owner Actions ───────────────────────────────────────────────────

  Widget _buildQuickActions(UserModel user) {
    final actions = [
      _QuickAction(
        icon: Icons.add_circle_outline_rounded,
        label: 'צור משמרת',
        color: const Color(0xFF4F46E5),
        onTap: () => _go(const CreateShiftScreen()),
      ),
      _QuickAction(
        icon: Icons.assignment_add,
        label: 'צור משימה',
        color: const Color(0xFF8B5CF6),
        onTap: () => _go(const CreateTaskFlowScreen()),
      ),
      _QuickAction(
        icon: Icons.campaign_rounded,
        label: 'פרסם הודעה',
        color: const Color(0xFFF59E0B),
        onTap: () => showDialog(
          context: context,
          builder: (_) => CreatePostDialog(
            authorId: user.uid,
            authorName: user.fullName,
            authorRole: user.role,
            authorProfilePicture: user.profilePicture,
          ),
        ),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'דוח שעות',
        color: const Color(0xFF0EA5E9),
        onTap: () => _go(const WorkersHoursReport()),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF7C3AED), size: 18),
              SizedBox(width: 8),
              Text(
                'פעולות מהירות',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: actions
                .map((a) => Expanded(child: _buildActionButton(a)))
                .toList()
                .expand((w) => [w, const SizedBox(width: 8)])
                .toList()
              ..removeLast(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: action.color.withOpacity(0.20),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(action.icon, color: action.color, size: 24),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: action.color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ── Workforce card ────────────────────────────────────────────────────────

  Widget _buildWorkforceCard() {
    final total = _kpi!.totalStaff == 0 ? 1 : _kpi!.totalStaff;
    final workerFrac = _kpi!.workersCount / total;
    final managerFrac = _kpi!.managersCount / total;

    return GestureDetector(
      onTap: () => _go(const ManageWorkersScreen()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: Color(0xFF7C3AED), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'כוח אדם',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Workers row
            _buildRoleRow(
              label: 'עובדים',
              count: _kpi!.workersCount,
              fraction: workerFrac,
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 12),
            // Managers row
            _buildRoleRow(
              label: 'מנהלים',
              count: _kpi!.managersCount,
              fraction: managerFrac,
              color: const Color(0xFF7C3AED),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 4),
                Text(
                  'סה"כ ${_kpi!.totalStaff} אנשים בצוות • לחץ לניהול',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleRow({
    required String label,
    required int count,
    required double fraction,
    required Color color,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Active workers card ───────────────────────────────────────────────────

  Widget _buildActiveWorkersCard() {
    final active = _kpi!.activeNow;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF10B981),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'נוכחים כעת',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${active.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (active.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  'אין עובדים מחוברים כרגע',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: active.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final w = active[i];
                  final elapsed = w.elapsed;
                  final hours = elapsed.inHours;
                  final minutes = elapsed.inMinutes.remainder(60);
                  final durationStr = hours > 0
                      ? '$hours:${minutes.toString().padLeft(2, '0')} ש׳'
                      : '$minutes דק׳';
                  final clockInStr = DateFormat('HH:mm').format(w.clockIn);
                  final firstName = w.name.trim().split(' ').first;

                  return GestureDetector(
                    onTap: () async {
                      final snap = await FirebaseFirestore.instance
                          .collection(AppConstants.usersCollection)
                          .where(FieldPath.documentId, isEqualTo: w.userId)
                          .limit(1)
                          .get();
                      if (snap.docs.isNotEmpty && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewWorkerScreen(
                              userData: snap.docs.first,
                              currentUserRole: 'owner',
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StorageAvatar(
                            url: w.profilePictureUrl,
                            path: w.profilePicturePath,
                            radius: 18,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            firstName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'מ-$clockInStr · $durationStr',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF94A3B8),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Shifts card ───────────────────────────────────────────────────────────

  Widget _buildShiftsCard() {
    return GestureDetector(
      onTap: () => _go(const ManagerWeeklyScheduleScreen()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.manage_history_rounded,
                      color: Color(0xFF4F46E5), size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'משמרות',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: _FillGauge(
                value: _kpi!.avgShiftFill,
                color: const Color(0xFF4F46E5),
                size: 80,
              ),
            ),
            const SizedBox(height: 12),
            _buildMiniStat(
              icon: Icons.today_rounded,
              label: 'היום',
              value: '${_kpi!.shiftsToday}',
              color: const Color(0xFF4F46E5),
            ),
            const SizedBox(height: 6),
            _buildMiniStat(
              icon: Icons.date_range_rounded,
              label: 'השבוע',
              value: '${_kpi!.shiftsThisWeek}',
              color: const Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tasks card ────────────────────────────────────────────────────────────

  Widget _buildTasksCard() {
    final total =
        _kpi!.openTasks + _kpi!.doneTasks == 0 ? 1 : _kpi!.openTasks + _kpi!.doneTasks;
    final donePercent =
        ((_kpi!.doneTasks / total) * 100).round();

    return GestureDetector(
      onTap: () => _go(const AllTasksScreen()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: Color(0xFF8B5CF6), size: 18),
                ),
                const SizedBox(width: 8),
                const Text(
                  'משימות',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    '$donePercent%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'הושלמו',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildMiniStat(
              icon: Icons.pending_actions_rounded,
              label: 'פתוחות',
              value: '${_kpi!.openTasks}',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 6),
            _buildMiniStat(
              icon: Icons.priority_high_rounded,
              label: 'דחוף',
              value: '${_kpi!.highPriorityTasks}',
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Workers card ──────────────────────────────────────────────────────

  Widget _buildTopWorkers() {
    final medals = ['🥇', '🥈', '🥉'];
    final medalColors = [
      const Color(0xFFF59E0B),
      const Color(0xFF94A3B8),
      const Color(0xFFCD7F32),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: Color(0xFFF59E0B), size: 20),
              SizedBox(width: 8),
              Text(
                'מובילי החודש',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_kpi!.topWorkers.length, (i) {
            final worker = _kpi!.topWorkers[i];
            final color = medalColors[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        medals[i],
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${worker.days} ימים החודש',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${worker.hours.toStringAsFixed(1)} ש׳',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Hours card ────────────────────────────────────────────────────────────

  Widget _buildHoursCard() {
    final avgHours = _kpi!.totalStaff > 0
        ? (_kpi!.totalHoursMonth / _kpi!.totalStaff)
        : 0.0;

    return GestureDetector(
      onTap: () => _go(const WorkersHoursReport()),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0369A1), Color(0xFF0EA5E9)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0EA5E9).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.access_time_filled_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'שעות עבודה — החודש',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_kpi!.totalHoursMonth.toStringAsFixed(1)} שעות',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'ממוצע ${avgHours.toStringAsFixed(1)} שעות לעובד',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white70, size: 24),
          ],
        ),
      ),
    );
  }

  // ── Mini stat row ─────────────────────────────────────────────────────────

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  PRIVATE DATA MODELS
// ══════════════════════════════════════════════════════════════════════════

class _StatPill {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatPill(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}


// ══════════════════════════════════════════════════════════════════════════
//  STORAGE-RESOLVED AVATAR
//  Shows the profile_picture URL if valid; otherwise fetches a download URL
//  from Firebase Storage using profile_picture_path as a fallback.
// ══════════════════════════════════════════════════════════════════════════

class _StorageAvatar extends StatefulWidget {
  final String? url;
  final String path;
  final double radius;

  const _StorageAvatar({
    required this.url,
    required this.path,
    required this.radius,
  });

  @override
  State<_StorageAvatar> createState() => _StorageAvatarState();
}

class _StorageAvatarState extends State<_StorageAvatar> {
  String? _resolvedUrl;

  @override
  void initState() {
    super.initState();
    final url = widget.url;
    if (url != null && url.startsWith('http')) {
      _resolvedUrl = url;
    } else {
      _resolveFromStorage();
    }
  }

  Future<void> _resolveFromStorage() async {
    try {
      final downloadUrl = await FirebaseStorage.instance
          .ref(widget.path)
          .getDownloadURL();
      if (mounted) setState(() => _resolvedUrl = downloadUrl);
    } catch (_) {
      // Path doesn't exist or no permission — default avatar will show
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileAvatar(imageUrl: _resolvedUrl, radius: widget.radius);
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  CIRCULAR FILL GAUGE
// ══════════════════════════════════════════════════════════════════════════

class _FillGauge extends StatelessWidget {
  final double value; // 0.0–1.0
  final Color color;
  final double size;

  const _FillGauge({
    required this.value,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GaugePainter(value: value, color: color),
        child: Center(
          child: Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final Color color;

  const _GaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const startAngle = -math.pi / 2;

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = color.withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Filled arc
    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * value.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}
