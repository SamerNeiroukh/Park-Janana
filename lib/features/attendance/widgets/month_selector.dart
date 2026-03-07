import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class MonthSelector extends StatelessWidget {
  final DateTime selectedMonth;
  final void Function(DateTime) onMonthChanged;

  const MonthSelector({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  void _changeMonth(int offset) {
    final newMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + offset,
    );
    onMonthChanged(newMonth);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final isCurrentMonth = DateTime(selectedMonth.year, selectedMonth.month)
        .isAtSameMomentAs(thisMonth);
    final formatted = DateFormat.yMMMM('he').format(selectedMonth);

    // Use explicit LTR so Row order matches visual order exactly
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: TaskTheme.surface,
          borderRadius: BorderRadius.circular(TaskTheme.radiusL),
          boxShadow: TaskTheme.softShadow,
        ),
        child: Row(
          children: [
            // Next month — left side of screen
            _buildArrowButton(
              icon: Icons.chevron_left_rounded,
              onTap: isCurrentMonth ? null : () => _changeMonth(1),
              enabled: !isCurrentMonth,
            ),
            Expanded(
              child: Center(
                child: Text(
                  formatted,
                  style: TaskTheme.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            // Prev month — right side of screen
            _buildArrowButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => _changeMonth(-1),
              enabled: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool enabled,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? TaskTheme.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? TaskTheme.primary : TaskTheme.border,
          ),
        ),
      ),
    );
  }
}
