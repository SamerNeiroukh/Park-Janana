import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../theme/task_theme.dart';

class TaskDeadlineText extends StatelessWidget {
  final DateTime dueDate;
  final bool showIcon;
  final double fontSize;

  const TaskDeadlineText({
    super.key,
    required this.dueDate,
    this.showIcon = true,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final diff = due.difference(today).inDays;

    String text;
    Color color;
    IconData icon;

    if (diff < 0) {
      text = 'באיחור ${diff.abs()} ${diff.abs() == 1 ? "יום" : "ימים"}';
      color = TaskTheme.overdue;
      icon = Icons.warning_amber_rounded;
    } else if (diff == 0) {
      text = 'היום, ${DateFormat('HH:mm').format(dueDate)}';
      color = dueDate.isAfter(now) ? TaskTheme.pending : TaskTheme.overdue;
      icon = Icons.today_rounded;
    } else if (diff == 1) {
      text = 'מחר, ${DateFormat('HH:mm').format(dueDate)}';
      color = TaskTheme.textSecondary;
      icon = Icons.event_rounded;
    } else if (diff <= 7) {
      text = 'בעוד $diff ימים';
      color = TaskTheme.textSecondary;
      icon = Icons.event_rounded;
    } else {
      text = DateFormat('dd/MM/yyyy').format(dueDate);
      color = TaskTheme.textTertiary;
      icon = Icons.calendar_today_rounded;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(icon, size: fontSize + 2, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
