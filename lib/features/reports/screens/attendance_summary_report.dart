import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/attendance/services/attendance_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/attendance/widgets/month_selector.dart';
import 'package:park_janana/features/attendance/widgets/user_summary_card.dart';
import 'package:park_janana/features/reports/services/pdf_export_service.dart';

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
      appBar: const UserHeader(),
      body: SafeArea(
        child: Column(
          children: [
            MonthSelector(
              selectedMonth: selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            UserSummaryCard(
              userName: widget.userName,
              profileUrl: widget.profileUrl,
              daysWorked: attendanceData?.daysWorked ?? 0,
              totalHours: attendanceData?.totalHoursWorked ?? 0.0,
              month: formattedMonth,
            ),
            if (isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (attendanceData == null)
              const Expanded(
                child: Center(child: Text('אין נתוני נוכחות זמינים לחודש זה')),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: attendanceData!.sessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final session = attendanceData!.sessions[index];
                            final date = DateFormat('dd/MM/yyyy').format(session.clockIn);
                            final clockIn = DateFormat('HH:mm').format(session.clockIn);
                            final clockOut = DateFormat('HH:mm').format(session.clockOut);
                            final duration = session.clockOut.difference(session.clockIn);
                            final hours = duration.inHours;
                            final minutes = duration.inMinutes.remainder(60);

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'תאריך: $date',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'שעת כניסה: $clockIn',
                                      textAlign: TextAlign.right,
                                    ),
                                    Text(
                                      'שעת יציאה: $clockOut',
                                      textAlign: TextAlign.right,
                                    ),
                                    Text(
                                      'משך העבודה: $hoursש׳ $minutesד׳',
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _exportToPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('צור קובץ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
