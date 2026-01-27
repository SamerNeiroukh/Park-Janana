import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/shift_model.dart';
import 'package:park_janana/services/report_service.dart';
import 'package:park_janana/services/pdf_export_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/attendance/month_selector.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/services/firebase_service.dart';
import 'package:park_janana/utils/profile_image_provider.dart'; // ✅ NEW

class WorkerShiftReport extends StatefulWidget {
  final String uid;
  final String fullName;

  /// Legacy URL (fallback)
  final String profilePicture;

  /// NEW: Firebase Storage path (preferred)
  final String? profilePicturePath;

  const WorkerShiftReport({
    super.key,
    required this.uid,
    required this.fullName,
    required this.profilePicture,
    this.profilePicturePath,
  });

  @override
  State<WorkerShiftReport> createState() => _WorkerShiftReportState();
}

class _WorkerShiftReportState extends State<WorkerShiftReport> {
  final FirebaseService _firebaseService = FirebaseService();
  late DateTime _selectedMonth;
  bool _isLoading = true;
  List<ShiftModel> _shifts = [];

  final Map<String, String> statusTranslations = {
    'active': 'פעילה',
    'cancelled': 'מבוטלת',
    'pending': 'ממתינה',
  };

  final Map<String, String> roleTranslations = {
    'worker': 'עובד',
    'shift_manager': 'מנהל משמרת',
    'department_manager': 'מנהל מחלקה',
    'manager': 'מנהל',
    'owner': 'בעלים',
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
    setState(() {
      _shifts = shifts;
      _isLoading = false;
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() => _selectedMonth = newMonth);
    _fetchShifts();
  }

  void _exportPdf() async {
    if (_shifts.isEmpty) return;

    final Set<String> allUids = {};
    for (final shift in _shifts) {
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

    await PdfExportService.exportShiftReportPdf(
      context: context,
      userName: widget.fullName,
      profileUrl: widget.profilePicture, // legacy for PDF
      shifts: _shifts,
      month: _selectedMonth,
      userId: widget.uid,
      uidToNameMap: uidToName,
    );
  }

  Future<String> _getFullName(String uid) async {
    try {
      final snapshot = await _firebaseService.getUser(uid);
      final data = snapshot.data() as Map<String, dynamic>?;
      return data?['fullName'] ?? uid;
    } catch (_) {
      return uid;
    }
  }

  Future<Widget> _buildWorkerMetadata(Map<String, dynamic> data) async {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    String? formatTime(dynamic ts) {
      if (ts is Timestamp) {
        return formatter.format(ts.toDate());
      }
      return null;
    }

    final decisionByName = data['decisionBy'] != null
        ? await _getFullName(data['decisionBy'])
        : null;
    final removedByName = data['removedBy'] != null
        ? await _getFullName(data['removedBy'])
        : null;
    final undoByName =
        data['undoBy'] != null ? await _getFullName(data['undoBy']) : null;

    final decision = data['decision'] ?? '';
    final Color decisionColor = {
          'accepted': Colors.green,
          'rejected': Colors.red,
        }[decision] ??
        Colors.grey;

    final String hebrewDecision = {
          'accepted': 'מאושר',
          'rejected': 'נדחה',
          'removed': 'הוסר',
          '': 'ממתין'
        }[decision] ??
        decision;

    final roleHebrew = roleTranslations[data['roleAtAssignment']] ??
        data['roleAtAssignment'] ??
        '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(hebrewDecision,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: decisionColor)),
          ],
        ),
        if (decisionByName != null) _infoLine('אושר ע״י', decisionByName),
        if (data['decisionAt'] != null)
          _infoLine('בתאריך', formatTime(data['decisionAt'])),
        if (roleHebrew.isNotEmpty) _infoLine('תפקיד בעת השיבוץ', roleHebrew),
        _infoLine('זמן בקשה', formatTime(data['requestedAt'])),
        if (removedByName != null) _infoLine('הוסר ע״י', removedByName),
        if (data['removedAt'] != null)
          _infoLine('זמן הסרה', formatTime(data['removedAt'])),
        if (undoByName != null) _infoLine('בוטל ע״י', undoByName),
        if (data['undoAt'] != null)
          _infoLine('זמן ביטול', formatTime(data['undoAt'])),
      ],
    );
  }

  Widget _infoLine(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text('$label: $value',
          style: const TextStyle(fontSize: 13, color: Colors.black87)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedMonth = DateFormat.yMMMM('he').format(_selectedMonth);

    return Scaffold(
      appBar: const UserHeader(),
      body: SafeArea(
        child: Column(
          children: [
            MonthSelector(
              selectedMonth: _selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    FutureBuilder<ImageProvider>(
                      future: ProfileImageProvider.resolve(
                        storagePath: widget.profilePicturePath,
                        fallbackUrl: widget.profilePicture,
                      ),
                      builder: (context, snapshot) {
                        return CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: snapshot.data,
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.fullName,
                              style: AppTheme.bodyText.copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(formattedMonth,
                              style: AppTheme.bodyText.copyWith(
                                  fontSize: 14, color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                    Text('סה״כ: ${_shifts.length}',
                        style: AppTheme.bodyText.copyWith(fontSize: 14)),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_shifts.isEmpty)
              const Expanded(
                  child: Center(child: Text('אין משמרות זמינות לחודש זה')))
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    itemCount: _shifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final shift = _shifts[index];
                      final userDataList = shift.assignedWorkerData
                          .where((data) => data['userId'] == widget.uid)
                          .toList();

                      userDataList.sort((a, b) {
                        final Timestamp aTime = a['decisionAt'] ??
                            a['requestedAt'] ??
                            Timestamp(0, 0);
                        final Timestamp bTime = b['decisionAt'] ??
                            b['requestedAt'] ??
                            Timestamp(0, 0);
                        return bTime.compareTo(aTime);
                      });

                      final Map<String, dynamic> userData =
                          userDataList.isNotEmpty
                              ? Map<String, dynamic>.from(userDataList.first)
                              : {};
                      final shiftStatusHebrew =
                          statusTranslations[shift.status] ?? shift.status;

                      return FutureBuilder<Widget>(
                        future: _buildWorkerMetadata(userData),
                        builder: (context, snapshot) {
                          return Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('📅 תאריך: ${shift.date}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(
                                      '🕒 שעות: ${shift.startTime} - ${shift.endTime}'),
                                  Text('🏷 מחלקה: ${shift.department}'),
                                  Text('סטטוס כללי: $shiftStatusHebrew'),
                                  const Divider(),
                                  snapshot.connectionState ==
                                          ConnectionState.done
                                      ? snapshot.data ?? const SizedBox()
                                      : const Center(
                                          child: CircularProgressIndicator()),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exportPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('צור קובץ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
