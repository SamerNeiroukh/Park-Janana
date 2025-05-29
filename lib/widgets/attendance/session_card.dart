import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/models/attendance_model.dart';

class SessionCard extends StatelessWidget {
  final AttendanceRecord session;

  const SessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(session.clockIn);
    final clockIn = DateFormat('HH:mm').format(session.clockIn);
    final clockOut = DateFormat('HH:mm').format(session.clockOut);
    final duration = session.clockOut.difference(session.clockIn);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('תאריך: $date'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 4),
            Text('שעת כניסה: $clockIn'),
            Text('שעת יציאה: $clockOut'),
            Text('משך העבודה: ${hours}ש׳ ${minutes}ד׳'),
          ],
        ),
      ),
    );
  }
}
