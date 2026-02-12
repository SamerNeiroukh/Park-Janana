import 'package:flutter/material.dart';

const List<String> allDepartments = [
  "פארק חבלים",
  "פיינטבול",
  "קרטינג",
  "פארק מים",
  "ג'ימבורי",
  "תפעול"
];

Color getDepartmentColor(String department) {
  switch (department) {
    case 'פארק חבלים':
      return const Color(0xFF43A047);
    case 'פיינטבול':
      return const Color(0xFFE53935);
    case 'קרטינג':
      return const Color(0xFFFF9800);
    case 'פארק מים':
      return const Color(0xFF1E88E5);
    case "ג'ימבורי":
      return const Color(0xFF8E24AA);
    case 'תפעול':
      return const Color(0xFF607D8B);
    default:
      return const Color(0xFF56C2F4);
  }
}

IconData getDepartmentIcon(String department) {
  switch (department) {
    case 'פארק חבלים':
      return Icons.park;
    case 'פיינטבול':
      return Icons.sports_esports;
    case 'קרטינג':
      return Icons.directions_car;
    case 'פארק מים':
      return Icons.pool;
    case "ג'ימבורי":
      return Icons.child_care;
    case 'תפעול':
      return Icons.build;
    default:
      return Icons.work;
  }
}
