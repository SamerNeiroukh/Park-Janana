import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart' as flutter;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:park_janana/models/attendance_model.dart';

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
          _buildHeader(userName, formattedMonth, imageLogo, ttf),
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

  static pw.Widget _buildHeader(String userName, String month, pw.ImageProvider logo, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // 📝 Hebrew Text on the left
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('דו״ח נוכחות חודשי', style: pw.TextStyle(font: font, fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.Text('שם העובד: $userName', style: pw.TextStyle(font: font, fontSize: 14)),
            pw.Text('חודש: $month', style: pw.TextStyle(font: font, fontSize: 14)),
          ],
        ),
        // 🖼 Logo on the right
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
    return pw.Table.fromTextArray(
      headers: ['משך', 'יציאה', 'כניסה', 'תאריך'], // ✅ RTL column order
      data: attendance.sessions.map((s) {
        final date = DateFormat('dd/MM/yyyy').format(s.clockIn);
        final inTime = DateFormat('HH:mm').format(s.clockIn);
        final outTime = DateFormat('HH:mm').format(s.clockOut);
        final duration = s.clockOut.difference(s.clockIn);
        final durationStr = '${duration.inHours}ש׳ ${duration.inMinutes.remainder(60)}ד׳';

        // ✅ Reverse the row to match RTL column order
        return [durationStr, outTime, inTime, date];
      }).toList(),
      headerStyle: pw.TextStyle(font: font, fontWeight: pw.FontWeight.bold),
      cellStyle: pw.TextStyle(font: font, fontSize: 12),
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
