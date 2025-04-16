import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_theme.dart';

class TaskDescriptionSection extends StatelessWidget {
  final String description;

  const TaskDescriptionSection({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'תיאור המשימה',
            style: AppTheme.sectionTitle,
          ),
          const SizedBox(height: 8.0),
          Text(
            description.isNotEmpty ? description : 'אין תיאור זמין.',
            style: AppTheme.bodyText,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
