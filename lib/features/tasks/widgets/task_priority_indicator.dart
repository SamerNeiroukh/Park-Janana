import 'package:flutter/material.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import '../theme/task_theme.dart';

class TaskPriorityIndicator extends StatelessWidget {
  final String priority;
  final bool showLabel;

  const TaskPriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  String _localizedLabel(AppLocalizations l10n, String priority) {
    switch (priority) {
      case 'high':
        return l10n.taskPriorityHigh;
      case 'low':
        return l10n.taskPriorityLow;
      default:
        return l10n.taskPriorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = TaskTheme.priorityColor(priority);
    final label = _localizedLabel(l10n, priority);
    final icon = TaskTheme.priorityIcon(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
