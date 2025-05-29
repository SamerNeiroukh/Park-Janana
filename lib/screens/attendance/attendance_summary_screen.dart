import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/models/attendance_model.dart';
import 'package:park_janana/services/attendance_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/attendance/month_selector.dart';
import 'package:park_janana/widgets/attendance/user_summary_card.dart';
import 'package:park_janana/widgets/attendance/session_card.dart';
import 'package:park_janana/services/pdf_export_service.dart';

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
    setState(() {
      attendanceData = data;
      isLoading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final formattedMonth = DateFormat.yMMMM('he').format(selectedMonth);
    return Scaffold(
      appBar: const UserHeader(), // Adjusted to remove title param
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MonthSelector(
            selectedMonth: selectedMonth,
            onMonthChanged: _onMonthChanged,
          ),
          if (isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (attendanceData == null)
            const Expanded(
              child: Center(child: Text('אין נתוני נוכחות זמינים לחודש זה')),
            )
          else ...[
            UserSummaryCard(
              userName: widget.userName,
              profileUrl: widget.profileUrl,
              daysWorked: attendanceData!.daysWorked,
              totalHours: attendanceData!.totalHoursWorked,
              month: formattedMonth,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: attendanceData!.sessions.length,
                itemBuilder: (context, index) {
                  final session = attendanceData!.sessions[index];
                  return SessionCard(session: session);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: _exportToPdf,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('ייצא כ-PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
