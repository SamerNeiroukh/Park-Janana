import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ➡️ Show NEXT only if not in current month
          if (!isCurrentMonth)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(1),
            )
          else
            const SizedBox(width: 48), // keep spacing even when hidden
          Text(
            formatted,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(-1),
          ),
        ],
      ),
    );
  }
}
