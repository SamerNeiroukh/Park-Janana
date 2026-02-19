import 'package:flutter/material.dart';

/// Centralized design system for the task management feature.
class TaskTheme {
  TaskTheme._();

  // ─── Colors ────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1);       // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  static const Color pending = Color(0xFFF59E0B);       // Amber
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color inProgress = Color(0xFF3B82F6);    // Blue
  static const Color inProgressBg = Color(0xFFDBEAFE);
  static const Color done = Color(0xFF10B981);           // Emerald
  static const Color doneBg = Color(0xFFD1FAE5);
  static const Color overdue = Color(0xFFEF4444);        // Rose
  static const Color overdueBg = Color(0xFFFEE2E2);

  static const Color highPriority = Color(0xFFEF4444);
  static const Color mediumPriority = Color(0xFFF59E0B);
  static const Color lowPriority = Color(0xFF94A3B8);

  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // ─── Status helpers ────────────────────────────────────────
  static Color statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return inProgress;
      case 'done':
        return done;
      default:
        return pending;
    }
  }

  static Color statusBgColor(String status) {
    switch (status) {
      case 'in_progress':
        return inProgressBg;
      case 'done':
        return doneBg;
      default:
        return pendingBg;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'in_progress':
        return 'בביצוע';
      case 'done':
        return 'הושלם';
      default:
        return 'ממתין';
    }
  }

  static IconData statusIcon(String status) {
    switch (status) {
      case 'in_progress':
        return Icons.play_circle_outline_rounded;
      case 'done':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  // ─── Priority helpers ──────────────────────────────────────
  static Color priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return highPriority;
      case 'medium':
        return mediumPriority;
      default:
        return lowPriority;
    }
  }

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return 'גבוהה';
      case 'medium':
        return 'בינונית';
      default:
        return 'נמוכה';
    }
  }

  static IconData priorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.keyboard_double_arrow_up_rounded;
      case 'medium':
        return Icons.remove_rounded;
      default:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  // ─── Department helpers ────────────────────────────────────
  static String departmentLabel(String key) {
    switch (key) {
      case 'paintball':
        return 'פיינטבול';
      case 'ropes':
        return 'פארק חבלים';
      case 'carting':
        return 'קרטינג';
      case 'water_park':
        return 'פארק מים';
      case 'jimbory':
        return 'ג\'ימבורי';
      default:
        return 'כללי';
    }
  }

  // ─── Shadows ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.35),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get topBarShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, -4),
    ),
  ];

  // ─── Border Radius ─────────────────────────────────────────
  static const double radiusS = 8;
  static const double radiusM = 12;
  static const double radiusL = 16;
  static const double radiusXL = 20;
  static const double radiusXXL = 24;

  // ─── Text Styles ───────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textTertiary,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
}
