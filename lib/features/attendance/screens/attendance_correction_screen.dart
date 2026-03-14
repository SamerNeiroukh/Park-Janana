// ignore_for_file: use_build_context_synchronously
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';

const _kIndigo = Color(0xFF6366F1);
const _kIndigoDark = Color(0xFF4F46E5);
const _kGreen = Color(0xFF10B981);
const _kRed = Color(0xFFEF4444);
const _kSlate = Color(0xFF0F172A);

class AttendanceCorrectionScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AttendanceCorrectionScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AttendanceCorrectionScreen> createState() =>
      _AttendanceCorrectionScreenState();
}

class _AttendanceCorrectionScreenState
    extends State<AttendanceCorrectionScreen> with TickerProviderStateMixin {
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month; // 1–12

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;
  List<AttendanceRecord> _sessions = [];

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  String get _docId =>
      '${widget.userId}_${_selectedYear}_'
      '${_selectedMonth.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadMonth();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ─── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadMonth() async {
    _fadeCtrl.reverse();
    setState(() {
      _isLoading = true;
      _sessions = [];
      _isDirty = false;
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.attendanceCollection)
          .doc(_docId)
          .get();
      if (snap.exists && snap.data() != null) {
        final model = AttendanceModel.fromMap(snap.data()!, _docId);
        setState(() => _sessions = List.from(model.sessions));
      }
    } catch (e) {
      debugPrint('AttendanceCorrectionScreen load error: $e');
    } finally {
      setState(() => _isLoading = false);
      _fadeCtrl.forward();
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.attendanceCollection)
          .doc(_docId)
          .set({
        'userId': widget.userId,
        'userName': widget.userName,
        'year': _selectedYear,
        'month': _selectedMonth,
        'sessions': _sessions.map((s) => s.toMap()).toList(),
      });
      if (mounted) {
        _showBanner(
          message: 'הנוכחות נשמרה בהצלחה',
          icon: Icons.check_circle_outline_rounded,
          color: _kGreen,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showBanner(
          message: 'שגיאה בשמירת הנוכחות',
          icon: Icons.error_outline_rounded,
          color: _kRed,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _editSession(int index) async {
    final session = _sessions[index];
    DateTime newClockIn = session.clockIn;
    DateTime newClockOut = session.clockOut;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditSessionDialog(
        clockIn: newClockIn,
        clockOut: newClockOut,
        onChanged: (ci, co) {
          newClockIn = ci;
          newClockOut = co;
        },
      ),
    );
    if (saved != true) return;

    setState(() {
      _sessions[index] = AttendanceRecord(
        clockIn: newClockIn,
        clockOut: newClockOut,
      );
      _isDirty = true;
    });
    _showBanner(
      message: 'הרשומה עודכנה — זכור לשמור',
      icon: Icons.edit_rounded,
      color: _kIndigo,
    );
  }

  Future<void> _addSession() async {
    final now = DateTime.now();
    final defaultDay =
        (_selectedYear == now.year && _selectedMonth == now.month)
            ? now.day
            : 1;
    DateTime newClockIn =
        DateTime(_selectedYear, _selectedMonth, defaultDay, 9, 0);
    DateTime newClockOut =
        DateTime(_selectedYear, _selectedMonth, defaultDay, 17, 0);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => _EditSessionDialog(
        clockIn: newClockIn,
        clockOut: newClockOut,
        onChanged: (ci, co) {
          newClockIn = ci;
          newClockOut = co;
        },
      ),
    );
    if (saved != true) return;

    setState(() {
      _sessions
          .add(AttendanceRecord(clockIn: newClockIn, clockOut: newClockOut));
      _sessions.sort((a, b) => a.clockIn.compareTo(b.clockIn));
      _isDirty = true;
    });
    _showBanner(
      message: 'רשומה נוספה — זכור לשמור',
      icon: Icons.add_circle_outline_rounded,
      color: _kGreen,
    );
  }

  void _deleteSession(int index) {
    final removed = _sessions[index];
    setState(() {
      _sessions.removeAt(index);
      _isDirty = true;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('רשומה מס׳ ${index + 1} נמחקה',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'בטל',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _sessions.insert(
                  index.clamp(0, _sessions.length), removed);
              _isDirty = true;
            });
          },
        ),
      ),
    );
  }

  void _showBanner({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(message,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            // ── Gradient section ──
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kIndigoDark, _kIndigo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  _buildMonthHeader(),
                  _buildMonthSelector(),
                  _buildStatsCard(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            // ── Sessions ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kIndigo))
                  : FadeTransition(
                      opacity: _fadeAnim,
                      child: _buildBody(),
                    ),
            ),
            if (!_isLoading) _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // ── Month header (like shifts week header) ──────────────────────────────────

  Widget _buildMonthHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          _navButton(
            icon: Icons.chevron_left,
            onTap: () {
              final minYear = DateTime.now().year - 2;
              if (_selectedYear > minYear) {
                setState(() => _selectedYear--);
                _loadMonth();
              }
            },
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'תיקון נוכחות',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_selectedYear',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _navButton(
            icon: Icons.chevron_right,
            onTap: () {
              final maxYear = DateTime.now().year;
              if (_selectedYear < maxYear) {
                setState(() => _selectedYear++);
                _loadMonth();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _navButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ── Month selector (like shifts day selector) ───────────────────────────────

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 80,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          reverse: true,
          itemCount: 12,
          itemBuilder: (context, i) {
            final monthNum = i + 1; // 1–12
            final isSelected = monthNum == _selectedMonth &&
                _selectedYear == _selectedYear;
            final monthDate = DateTime(_selectedYear, monthNum);
            final isCurrentMonth = monthNum == DateTime.now().month &&
                _selectedYear == DateTime.now().year;

            return GestureDetector(
              onTap: () {
                if (_selectedMonth == monthNum) return;
                setState(() => _selectedMonth = monthNum);
                _loadMonth();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: 62,
                margin:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Colors.white, Color(0xFFE8E9FF)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isCurrentMonth && !isSelected
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 1.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM', 'he').format(monthDate),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? _kIndigoDark
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _kIndigo.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$monthNum',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? _kIndigo
                                : isCurrentMonth
                                    ? Colors.white
                                    : Colors.white
                                        .withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Glass stats card ────────────────────────────────────────────────────────

  Widget _buildStatsCard() {
    final completedSessions =
        _sessions.where((s) => s.clockIn != s.clockOut).toList();
    final now = DateTime.now();
    final openSessions = _sessions
        .where((s) =>
            (s.clockIn == s.clockOut && now.difference(s.clockIn).inHours >= 16) ||
            (s.clockIn != s.clockOut && s.hoursWorked >= 16))
        .length;
    final totalHours =
        completedSessions.fold(0.0, (acc, s) => acc + s.hoursWorked);
    final uniqueDays =
        completedSessions.map((s) => s.clockIn.day).toSet().length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              children: [
                _statItem(
                  icon: Icons.calendar_today_rounded,
                  value: '$uniqueDays',
                  label: 'ימי עבודה',
                ),
                _statDivider(),
                _statItem(
                  icon: Icons.access_time_rounded,
                  value: totalHours.toStringAsFixed(1),
                  label: 'שעות',
                ),
                _statDivider(),
                _statItem(
                  icon: Icons.receipt_long_rounded,
                  value: '${_sessions.length}',
                  label: 'רשומות',
                ),
                if (openSessions > 0) ...[
                  _statDivider(),
                  _statItem(
                    icon: Icons.timer_off_rounded,
                    value: '$openSessions',
                    label: 'חסר יציאה',
                    highlight: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statItem({
    required IconData icon,
    required String value,
    required String label,
    bool highlight = false,
  }) {
    final color = highlight ? const Color(0xFFFBBF24) : Colors.white;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: color.withValues(alpha: 0.85)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.2),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );

  // ── Body ────────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: _kIndigo.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 52,
                color: _kIndigo.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'אין רשומות נוכחות לחודש זה',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'הוסף רשומה ידנית או בחר חודש אחר',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addSession,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('הוסף רשומה'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kIndigo,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(),
      itemCount: _sessions.length,
      itemBuilder: (_, i) => _buildSessionTile(i),
    );
  }

  Widget _buildSessionTile(int index) {
    final s = _sessions[index];
    final dateFmt = DateFormat('dd/MM');
    final timeFmt = DateFormat('HH:mm');
    final isOngoing = s.clockIn == s.clockOut;
    final isMissedClockout = (isOngoing && DateTime.now().difference(s.clockIn).inHours >= 16)
        || (!isOngoing && s.hoursWorked >= 16);
    // For missed clock-out, cap displayed hours at 16; for still-working sessions show elapsed (up to 16)
    final hours = isOngoing
        ? DateTime.now().difference(s.clockIn).inHours.clamp(0, 16).toDouble()
        : s.hoursWorked;

    return Dismissible(
      key: ValueKey('${s.clockIn.millisecondsSinceEpoch}_$index'),
      direction: DismissDirection.startToEnd,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: _kRed,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_sweep_rounded,
            color: Colors.white, size: 28),
      ),
      onDismissed: (_) => _deleteSession(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isMissedClockout
              ? Border.all(color: const Color(0xFFF97316), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isMissedClockout
                  ? const Color(0xFFF97316).withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _editSession(index),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Session number badge
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      gradient: isMissedClockout
                          ? const LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [_kIndigo, _kIndigoDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Date column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFmt.format(s.clockIn),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (hours > 0)
                        Text(
                          '${hours.toStringAsFixed(1)}h',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _kIndigo.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Times
                  Expanded(
                    child: Row(
                      children: [
                        // Clock In
                        _timeChip(
                          icon: Icons.login_rounded,
                          time: timeFmt.format(s.clockIn),
                          color: _kGreen,
                          label: 'כניסה',
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.arrow_back_rounded,
                              size: 16, color: Color(0xFFCBD5E1)),
                        ),
                        // Clock Out
                        _timeChip(
                          icon: Icons.logout_rounded,
                          time: isOngoing ? '...' : timeFmt.format(s.clockOut),
                          color: isMissedClockout
                              ? const Color(0xFFF97316)
                              : isOngoing
                                  ? _kGreen.withValues(alpha: 0.7)
                                  : _kRed,
                          label: isMissedClockout
                              ? 'חסר'
                              : isOngoing
                                  ? 'פעיל'
                                  : 'יציאה',
                          isAlert: isMissedClockout,
                        ),
                      ],
                    ),
                  ),
                  // Edit hint
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined,
                      size: 18,
                      color: _kIndigo.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeChip({
    required IconData icon,
    required String time,
    required Color color,
    required String label,
    bool isAlert = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isAlert ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 3),
              Text(
                time,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add button — always visible when loaded
          if (_sessions.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _addSession,
                icon: const Icon(Icons.add_rounded, size: 18, color: _kIndigo),
                label: const Text(
                  'הוסף רשומה',
                  style: TextStyle(
                      color: _kIndigo, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: _kIndigo, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          // Save button — animated in/out when dirty
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _isDirty
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kIndigo,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'שמור שינויים',
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
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Edit / Add Session Dialog ────────────────────────────────────────────────

class _EditSessionDialog extends StatefulWidget {
  final DateTime clockIn;
  final DateTime clockOut;
  final void Function(DateTime clockIn, DateTime clockOut) onChanged;

  const _EditSessionDialog({
    required this.clockIn,
    required this.clockOut,
    required this.onChanged,
  });

  @override
  State<_EditSessionDialog> createState() => _EditSessionDialogState();
}

class _EditSessionDialogState extends State<_EditSessionDialog> {
  late DateTime _clockIn;
  late DateTime _clockOut;

  @override
  void initState() {
    super.initState();
    _clockIn = widget.clockIn;
    _clockOut = widget.clockOut;
  }

  Future<void> _pickDateTime(bool isIn) async {
    final initial = isIn ? _clockIn : _clockOut;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kIndigo),
        ),
        child: child!,
      ),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kIndigo),
        ),
        child: child!,
      ),
    );
    if (time == null) return;
    final result =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isIn) {
        _clockIn = result;
      } else {
        _clockOut = result;
      }
    });
    widget.onChanged(_clockIn, _clockOut);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('EEEE, dd/MM/yyyy', 'he');
    final timeFmt = DateFormat('HH:mm');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'עריכת רשומת נוכחות',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kSlate,
                ),
              ),
              const SizedBox(height: 20),
              _DialogTimeRow(
                icon: Icons.login_rounded,
                color: _kGreen,
                label: 'כניסה',
                date: fmt.format(_clockIn),
                time: timeFmt.format(_clockIn),
                onTap: () => _pickDateTime(true),
              ),
              const SizedBox(height: 12),
              _DialogTimeRow(
                icon: Icons.logout_rounded,
                color: _kRed,
                label: 'יציאה',
                date: fmt.format(_clockOut),
                time: timeFmt.format(_clockOut),
                onTap: () => _pickDateTime(false),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('ביטול'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kIndigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'שמור',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTimeRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String date;
  final String time;
  final VoidCallback onTap;

  const _DialogTimeRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.date,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _kSlate,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
