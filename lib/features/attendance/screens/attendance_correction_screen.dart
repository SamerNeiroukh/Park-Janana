// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';

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
    extends State<AttendanceCorrectionScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  bool _isSaving = false;

  // Edited sessions (mutable copy)
  List<AttendanceRecord> _sessions = [];

  String get _docId =>
      '${widget.userId}_${_selectedMonth.year}_'
      '${_selectedMonth.month.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadMonth();
  }

  Future<void> _loadMonth() async {
    setState(() {
      _isLoading = true;
      _sessions = [];
    });
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.attendanceCollection)
          .doc(_docId)
          .get();
      if (snap.exists && snap.data() != null) {
        final model = AttendanceModel.fromMap(snap.data()!, _docId);
        setState(() {
          _sessions = List.from(model.sessions);
        });
      }
    } catch (e) {
      debugPrint('AttendanceCorrectionScreen load error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.attendanceCollection)
          .doc(_docId)
          .update({'sessions': _sessions.map((s) => s.toMap()).toList()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('הנוכחות עודכנה בהצלחה'),
            ]),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('שגיאה בשמירת הנוכחות')),
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
    });
  }

  void _deleteSession(int index) {
    setState(() => _sessions.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            _buildHeader(),
            Expanded(child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody()),
            if (!_isLoading && _sessions.isNotEmpty) _buildSaveBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final months = List.generate(12, (i) {
      final d = DateTime(_selectedMonth.year, _selectedMonth.month - i);
      return d;
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('תיקון נוכחות — ${widget.userName}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: months.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final m = months[i];
                final isSelected = m.year == _selectedMonth.year &&
                    m.month == _selectedMonth.month;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMonth = m);
                    _loadMonth();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6366F1)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      DateFormat('MMM yyyy', 'he').format(m),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
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

  Widget _buildBody() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded,
                size: 56, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              'אין רשומות נוכחות לחודש זה',
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _sessions.length,
      itemBuilder: (_, i) => _buildSessionTile(i),
    );
  }

  Widget _buildSessionTile(int index) {
    final s = _sessions[index];
    final fmt = DateFormat('dd/MM HH:mm');
    final isOngoing = s.clockIn == s.clockOut;
    final hours = isOngoing ? 0.0 : s.hoursWorked;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                    fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.login_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(fmt.format(s.clockIn),
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.logout_rounded,
                      size: 14,
                      color: isOngoing ? Colors.orange : const Color(0xFFEF4444)),
                  const SizedBox(width: 4),
                  Text(
                    isOngoing ? 'עדיין בעבודה' : fmt.format(s.clockOut),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isOngoing ? Colors.orange : null),
                  ),
                ]),
                if (!isOngoing) ...[
                  const SizedBox(height: 4),
                  Text('${hours.toStringAsFixed(1)} שעות',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                color: Color(0xFF6366F1), size: 20),
            onPressed: () => _editSession(index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                color: Color(0xFFEF4444), size: 20),
            onPressed: () => _deleteSession(index),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('שמור שינויים',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Edit session dialog ─────────────────────────────────────────────────────

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
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
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
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('עריכת רשומת נוכחות'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.login_rounded, color: Color(0xFF10B981)),
              title: const Text('כניסה'),
              subtitle: Text(fmt.format(_clockIn)),
              onTap: () => _pickDateTime(true),
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
              title: const Text('יציאה'),
              subtitle: Text(fmt.format(_clockOut)),
              onTap: () => _pickDateTime(false),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1)),
            child: const Text('שמור', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
