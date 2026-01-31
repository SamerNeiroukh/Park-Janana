// ✅ Your original imports remain unchanged
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' as flutter;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';

class PdfExportService {
  static Future<void> exportAttendancePdf({
    required flutter.BuildContext context,
    required String userName,
    required String profileUrl,
    required AttendanceModel attendance,
    required DateTime month,
  }) async {
    final pdf = pw.Document();
    final ttf = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'));
    final imageLogo = await imageFromAssetBundle('assets/images/park_logo.png');
    final formattedMonth = DateFormat.yMMMM('he').format(month);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          _buildHeader(
              'דו״ח נוכחות חודשי', userName, formattedMonth, imageLogo, ttf),
          pw.SizedBox(height: 10),
          _buildSummary(attendance, ttf),
          pw.SizedBox(height: 10),
          _buildSessionTable(attendance, ttf),
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'דו״ח נוכחות - $formattedMonth.pdf');
  }

  static Future<void> exportTaskReportPdf({
    required flutter.BuildContext context,
    required String userName,
    required String profileUrl,
    required List<TaskModel> tasks,
    required DateTime month,
    required String userId,
  }) async {
    final pdf = pw.Document();
    final ttf = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'));
    final imageLogo = await imageFromAssetBundle('assets/images/park_logo.png');
    final formattedMonth = DateFormat.yMMMM('he').format(month);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          _buildHeader('דו״ח משימות', userName, formattedMonth, imageLogo, ttf),
          pw.SizedBox(height: 10),
          _buildExpandedTaskTable(tasks, userId, ttf),
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'דו״ח משימות - $formattedMonth.pdf');
  }

  static Future<void> exportShiftReportPdf({
    required flutter.BuildContext context,
    required String userName,
    required String profileUrl,
    required List<ShiftModel> shifts,
    required DateTime month,
    required String userId,
    required Map<String, String> uidToNameMap, // ✅ NEW
  }) async {
    final pdf = pw.Document();
    final ttf = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'));
    final imageLogo = await imageFromAssetBundle('assets/images/park_logo.png');
    final formattedMonth = DateFormat.yMMMM('he').format(month);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttf),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          _buildHeader('דו״ח משמרות', userName, formattedMonth, imageLogo, ttf),
          pw.SizedBox(height: 10),
          ..._buildShiftDetails(
              shifts, userId, uidToNameMap, ttf), // ✅ Pass map
        ],
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'דו״ח משמרות - $formattedMonth.pdf');
  }

  static pw.Widget _buildHeader(String title, String userName, String month,
      pw.ImageProvider logo, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                    font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('שם העובד: $userName',
                style: pw.TextStyle(font: font, fontSize: 14)),
            pw.Text('חודש: $month',
                style: pw.TextStyle(font: font, fontSize: 14)),
          ],
        ),
        pw.Image(logo, width: 60),
      ],
    );
  }

  static pw.Widget _buildSummary(AttendanceModel attendance, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('סה״כ ימים: ${attendance.daysWorked}',
              style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text(
              'סה״כ שעות: ${attendance.totalHoursWorked.toStringAsFixed(1)}',
              style: pw.TextStyle(font: font, fontSize: 14)),
        ],
      ),
    );
  }

  static pw.Widget _buildSessionTable(
      AttendanceModel attendance, pw.Font font) {
    return pw.TableHelper.fromTextArray(
      headers: ['משך', 'יציאה', 'כניסה', 'תאריך'],
      data: attendance.sessions.map((s) {
        final date = DateFormat('dd/MM/yyyy').format(s.clockIn);
        final inTime = DateFormat('HH:mm').format(s.clockIn);
        final outTime = DateFormat('HH:mm').format(s.clockOut);
        final duration = s.clockOut.difference(s.clockIn);
        final durationStr =
            '${duration.inHours}ש׳ ${duration.inMinutes.remainder(60)}ד׳';

        return [durationStr, outTime, inTime, date];
      }).toList(),
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 12),
      cellAlignment: pw.Alignment.centerRight,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey),
    );
  }

  static pw.Widget _buildExpandedTaskTable(
      List<TaskModel> tasks, String userId, pw.Font font) {
    return pw.TableHelper.fromTextArray(
      headers: [
        'סיום',
        'התחלה',
        'הוגש',
        'סטטוס עובד',
        'תאריך יעד',
        'תיאור',
        'משימה'
      ],
      data: tasks.map((task) {
        final dueDate = (task.dueDate).toDate();
        final progress = task.workerProgress[userId] ?? {};

        String formatTs(dynamic ts) {
          if (ts is Timestamp) {
            return DateFormat('dd/MM/yy HH:mm').format(ts.toDate());
          }
          return 'לא ידוע';
        }

        return [
          formatTs(progress['endedAt']),
          formatTs(progress['startedAt']),
          formatTs(progress['submittedAt']),
          progress['status'] ?? 'לא ידוע',
          DateFormat('dd/MM/yy HH:mm').format(dueDate),
          task.description,
          task.title,
        ];
      }).toList(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.3),
        1: const pw.FlexColumnWidth(1.3),
        2: const pw.FlexColumnWidth(1.3),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.8),
        5: const pw.FlexColumnWidth(2.2),
        6: const pw.FlexColumnWidth(2.2),
      },
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 11),
      cellAlignment: pw.Alignment.centerRight,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey),
    );
  }

  static List<pw.Widget> _buildShiftDetails(List<ShiftModel> shifts,
      String userId, Map<String, String> uidToNameMap, pw.Font font) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final List<pw.Widget> widgets = [];

    String resolveName(dynamic uid) =>
        uidToNameMap[uid] ?? uid?.toString() ?? '---';

    for (final shift in shifts) {
      final allEntries = shift.assignedWorkerData
          .where((data) => data['userId'] == userId)
          .toList();

      allEntries.sort((a, b) {
        final aTime = a['decisionAt'] ?? a['requestedAt'];
        final bTime = b['decisionAt'] ?? b['requestedAt'];
        return (bTime as Timestamp).compareTo(aTime as Timestamp);
      });

      final workerData = allEntries.isNotEmpty ? allEntries.first : {};

      final decision = workerData['decision'] ?? '';
      final decisionColor = {
            'accepted': PdfColors.green,
            'rejected': PdfColors.red,
            'removed': PdfColors.orange,
          }[decision] ??
          PdfColors.grey;

      final hebrewDecision = {
            'accepted': 'מאושר',
            'rejected': 'נדחה',
            'removed': 'הוסר',
            '': 'ממתין'
          }[decision] ??
          decision;

      final statusTranslation = {
        'active': 'פעילה',
        'cancelled': 'מבוטלת',
        'pending': 'ממתינה',
        '': 'לא ידוע'
      };
      final hebrewStatus = statusTranslation[shift.status] ?? shift.status;

      String? format(dynamic val) {
        if (val == null) return null;
        return val is Timestamp
            ? formatter.format(val.toDate())
            : val.toString();
      }

      pw.Widget infoLine(String label, dynamic value) {
        final formatted = format(value);
        if (formatted == null || formatted.isEmpty) return pw.SizedBox();
        return pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text('$label:',
                style: pw.TextStyle(
                    font: font, fontSize: 11, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.right),
            pw.SizedBox(width: 6),
            pw.Text(formatted,
                style: pw.TextStyle(font: font, fontSize: 11),
                textAlign: pw.TextAlign.right),
          ],
        );
      }

      widgets.add(
        pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Container(
            alignment: pw.Alignment.centerRight,
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('תאריך: ${shift.date}',
                    style: pw.TextStyle(
                        font: font,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13),
                    textAlign: pw.TextAlign.right),
                pw.Text('שעות: ${shift.startTime} - ${shift.endTime}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                    textAlign: pw.TextAlign.right),
                pw.Text('מחלקה: ${shift.department}',
                    style: pw.TextStyle(font: font, fontSize: 12),
                    textAlign: pw.TextAlign.right),
                pw.Text('סטטוס כללי: $hebrewStatus',
                    style: pw.TextStyle(font: font, fontSize: 12),
                    textAlign: pw.TextAlign.right),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('החלטה:',
                        style: pw.TextStyle(font: font, fontSize: 12),
                        textAlign: pw.TextAlign.right),
                    pw.SizedBox(width: 6),
                    pw.Text(hebrewDecision,
                        style: pw.TextStyle(
                            font: font,
                            color: decisionColor,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12),
                        textAlign: pw.TextAlign.right),
                  ],
                ),
                infoLine('אושר ע״י', resolveName(workerData['decisionBy'])),
                infoLine('בתאריך', workerData['decisionAt']),
                infoLine('תפקיד בעת השיבוץ',
                    _translateRole(workerData['roleAtAssignment'])),
                infoLine('זמן בקשה', workerData['requestedAt']),
                infoLine('הוסר ע״י', resolveName(workerData['removedBy'])),
                infoLine('זמן הסרה', workerData['removedAt']),
                infoLine('בוטל ע״י', resolveName(workerData['undoBy'])),
                infoLine('זמן ביטול', workerData['undoAt']),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  static String _translateRole(String? role) {
    switch (role) {
      case 'worker':
        return 'עובד';
      case 'shiftManager':
        return 'אחראי משמרת';
      case 'departmentManager':
        return 'מנהל מחלקה';
      case 'manager':
        return 'מנהל ראשי';
      case 'owner':
        return 'בעלים';
      default:
        return role ?? '---';
    }
  }

  static Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
    final byteData = await rootBundle.load(path);
    return pw.MemoryImage(byteData.buffer.asUint8List());
  }
}
