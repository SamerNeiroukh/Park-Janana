import 'package:flutter/material.dart';
import '../theme/task_theme.dart';

class TaskStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const TaskStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = TaskTheme.statusColor(status);
    final bgColor = TaskTheme.statusBgColor(status);
    final label = TaskTheme.statusLabel(status);
    final icon = TaskTheme.statusIcon(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
