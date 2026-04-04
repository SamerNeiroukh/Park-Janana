import 'package:flutter/material.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import '../theme/task_theme.dart';

class TaskStatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const TaskStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  String _localizedLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'in_progress':
        return l10n.taskStatusInProgress;
      case 'pending_review':
        return l10n.taskStatusPendingReview;
      case 'done':
        return l10n.taskStatusDone;
      default:
        return l10n.taskStatusPending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = TaskTheme.statusColor(status);
    final bgColor = TaskTheme.statusBgColor(status);
    final label = _localizedLabel(l10n, status);
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
