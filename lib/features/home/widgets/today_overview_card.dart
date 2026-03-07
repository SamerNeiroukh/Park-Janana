import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// "מה חשוב עכשיו" — Smart Context Panel.
///
/// Dynamic, data-driven panel that surfaces what needs attention right now.
/// Premium redesign: gradient header icon, coloured icon circles per item,
/// gradient count badges, and a clean divider between rows.
class SmartContextPanel extends StatelessWidget {
  final String role;
  final int shiftsBadge;
  final int tasksBadge;
  final int newsfeedBadge;

  const SmartContextPanel({
    super.key,
    required this.role,
    required this.shiftsBadge,
    required this.tasksBadge,
    required this.newsfeedBadge,
  });

  // ── Role-specific item definitions ────────────────────────────────────

  List<_ContextItem> _items() {
    final allClear = shiftsBadge == 0 && tasksBadge == 0 && newsfeedBadge == 0;

    if (allClear) {
      return const [
        _ContextItem(
          color: Color(0xFF22C55E),
          icon: Icons.check_circle_outline_rounded,
          text: 'הכל מעודכן — אין פריטים דחופים',
          count: 0,
        ),
      ];
    }

    switch (role) {
      case 'manager':
        return [
          if (shiftsBadge > 0)
            _ContextItem(
              color: const Color(0xFF3B82F6),
              icon: Icons.schedule_rounded,
              text: 'שינויים במשמרות ממתינים',
              count: shiftsBadge,
            ),
          if (tasksBadge > 0)
            _ContextItem(
              color: const Color(0xFF8B5CF6),
              icon: Icons.assignment_outlined,
              text: 'משימות ממתינות לאישור',
              count: tasksBadge,
            ),
          if (newsfeedBadge > 0)
            _ContextItem(
              color: const Color(0xFFF59E0B),
              icon: Icons.newspaper_rounded,
              text: 'פוסטים חדשים בלוח המודעות',
              count: newsfeedBadge,
            ),
        ];

      case 'owner':
        return [
          if (newsfeedBadge > 0)
            _ContextItem(
              color: const Color(0xFF3B82F6),
              icon: Icons.newspaper_rounded,
              text: 'עדכונים חדשים בלוח המודעות',
              count: newsfeedBadge,
            ),
          if (tasksBadge > 0)
            _ContextItem(
              color: const Color(0xFFF59E0B),
              icon: Icons.bar_chart_rounded,
              text: 'פעילות עסקית חדשה לבדיקה',
              count: tasksBadge,
            ),
        ];

      default: // worker
        return [
          if (shiftsBadge > 0)
            _ContextItem(
              color: const Color(0xFF3B82F6),
              icon: Icons.schedule_rounded,
              text: 'משמרות חדשות שהוקצו לך',
              count: shiftsBadge,
            ),
          if (tasksBadge > 0)
            _ContextItem(
              color: const Color(0xFF8B5CF6),
              icon: Icons.task_outlined,
              text: 'משימות פתוחות ממתינות לך',
              count: tasksBadge,
            ),
          if (newsfeedBadge > 0)
            _ContextItem(
              color: const Color(0xFFF59E0B),
              icon: Icons.campaign_outlined,
              text: 'עדכונים חדשים בלוח המודעות',
              count: newsfeedBadge,
            ),
        ];
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final items = _items();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4F46E5),
                            Color(0xFF7C3AED),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'מה חשוב עכשיו',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Context items ─────────────────────────────────
                ...List.generate(items.length, (i) {
                  final item = items[i];
                  final isLast = i == items.length - 1;
                  return Column(
                    children: [
                      _ContextRow(item: item),
                      if (!isLast)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF3F4F6),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
            duration: 450.ms,
            delay: 80.ms,
            curve: Curves.easeOut)
        .slideY(
            begin: 0.06,
            end: 0,
            duration: 450.ms,
            delay: 80.ms,
            curve: Curves.easeOut);
  }
}

// ── Context row ────────────────────────────────────────────────────────────

class _ContextRow extends StatelessWidget {
  final _ContextItem item;

  const _ContextRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Coloured icon circle
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(item.icon, size: 19, color: item.color),
        ),
        const SizedBox(width: 12),
        // Label
        Expanded(
          child: Text(
            item.text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ),
        // Gradient count badge
        if (item.count > 0)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  item.color,
                  item.color.withOpacity(0.72),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.30),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${item.count}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Private data model ──────────────────────────────────────────────────────

class _ContextItem {
  final Color color;
  final IconData icon;
  final String text;
  final int count;

  const _ContextItem({
    required this.color,
    required this.icon,
    required this.text,
    required this.count,
  });
}
