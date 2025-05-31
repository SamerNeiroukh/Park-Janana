import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' as flutter;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/attendance_model.dart';
import 'package:park_janana/models/task_model.dart';

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
      await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'),
    );

    final imageLogo = await imageFromAssetBundle('assets/images/park_logo.png');
    final formattedMonth = DateFormat.yMMMM('he').format(month);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          _buildHeader('דו״ח נוכחות חודשי', userName, formattedMonth, imageLogo, ttf),
          pw.SizedBox(height: 10),
          _buildSummary(attendance, ttf),
          pw.SizedBox(height: 10),
          _buildSessionTable(attendance, ttf),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'דו״ח נוכחות - $formattedMonth.pdf',
    );
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
      await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'),
    );

    final imageLogo = await imageFromAssetBundle('assets/images/park_logo.png');
    final formattedMonth = DateFormat.yMMMM('he').format(month);

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttf,
        ),
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) => [
          _buildHeader('דו״ח משימות', userName, formattedMonth, imageLogo, ttf),
          pw.SizedBox(height: 10),
          _buildExpandedTaskTable(tasks, userId, ttf),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'דו״ח משימות - $formattedMonth.pdf',
    );
  }

  static pw.Widget _buildHeader(
    String title,
    String userName,
    String month,
    pw.ImageProvider logo,
    pw.Font font,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('שם העובד: $userName', style: pw.TextStyle(font: font, fontSize: 14)),
            pw.Text('חודש: $month', style: pw.TextStyle(font: font, fontSize: 14)),
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
          pw.Text('סה״כ ימים: ${attendance.daysWorked}', style: pw.TextStyle(font: font, fontSize: 14)),
          pw.Text('סה״כ שעות: ${attendance.totalHoursWorked.toStringAsFixed(1)}', style: pw.TextStyle(font: font, fontSize: 14)),
        ],
      ),
    );
  }

  static pw.Widget _buildSessionTable(AttendanceModel attendance, pw.Font font) {
    return pw.TableHelper.fromTextArray(
      headers: ['משך', 'יציאה', 'כניסה', 'תאריך'],
      data: attendance.sessions.map((s) {
        final date = DateFormat('dd/MM/yyyy').format(s.clockIn);
        final inTime = DateFormat('HH:mm').format(s.clockIn);
        final outTime = DateFormat('HH:mm').format(s.clockOut);
        final duration = s.clockOut.difference(s.clockIn);
        final durationStr = '${duration.inHours}ש׳ ${duration.inMinutes.remainder(60)}ד׳';

        return [durationStr, outTime, inTime, date];
      }).toList(),
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 12),
      cellAlignment: pw.Alignment.centerRight,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      border: pw.TableBorder.all(color: PdfColors.grey),
    );
  }

  static pw.Widget _buildExpandedTaskTable(List<TaskModel> tasks, String userId, pw.Font font) {
  return pw.TableHelper.fromTextArray(
    headers: ['סיום', 'התחלה', 'הוגש', 'סטטוס עובד', 'תאריך יעד', 'תיאור', 'משימה'],
    data: tasks.map((task) {
      final dueDate = (task.dueDate as Timestamp).toDate();
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
      4: const pw.FlexColumnWidth(1.8), // ⬅ Wider column for date+time
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



  static Future<pw.ImageProvider> imageFromAssetBundle(String path) async {
    final byteData = await rootBundle.load(path);
    return pw.MemoryImage(byteData.buffer.asUint8List());
  }
}
