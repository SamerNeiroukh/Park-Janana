import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';

class SessionCard extends StatelessWidget {
  final AttendanceRecord session;

  const SessionCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        title: Text(l10n.datePrefix(date)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 4),
            Text(l10n.clockInTimePrefix(clockIn)),
            Text(l10n.clockOutTimePrefix(clockOut)),
            Text(l10n.workDurationLabel(hours, minutes)),
          ],
        ),
      ),
    );
  }
}
