import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';

class TaskDescriptionSection extends StatelessWidget {
  final String description;
  final String time;
  final String dateFormatted;
  final bool isManager;
  final TaskModel task;

  const TaskDescriptionSection({
    super.key,
    required this.description,
    required this.time,
    required this.dateFormatted,
    required this.isManager,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l10n.taskDescriptionSectionTitle,
            style: AppTheme.sectionTitle,
          ),
          const SizedBox(height: 8.0),
          Text(
            description.isNotEmpty ? description : l10n.noTaskDescription,
            style: AppTheme.bodyText,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.clock, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(PhosphorIconsRegular.calendarBlank, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    dateFormatted,
                    style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          if (isManager)
            Text(
              "${l10n.taskCreatedAtLabel}: ${task.createdBy}",
              style: AppTheme.bodyText,
              textAlign: TextAlign.right,
            ),
        ],
      ),
    );
  }
}
