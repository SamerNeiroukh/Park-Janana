// File: lib/widgets/task/task_header_section.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

class TaskHeaderSection extends StatelessWidget {
  final String title;
  final String status;
  final DateTime dueDate;

  const TaskHeaderSection({
    super.key,
    required this.title,
    required this.status,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final String time = DateFormat('HH:mm').format(dueDate);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatusChip(context, l10n, status),
        Text(
          time,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, AppLocalizations l10n, String status) {
    Color color;
    String label;

    switch (status) {
      case 'in_progress':
        color = Colors.orange;
        label = l10n.taskStatusInProgress;
        break;
      case 'done':
        color = Colors.green;
        label = l10n.taskStatusDone;
        break;
      default:
        color = Colors.red;
        label = l10n.taskStatusPending;
    }

    return Chip(
      backgroundColor: color.withValues(alpha: 0.15),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
