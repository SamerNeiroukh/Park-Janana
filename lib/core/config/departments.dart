import 'package:flutter/material.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
      return PhosphorIconsRegular.tree;
    case 'פיינטבול':
      return PhosphorIconsRegular.gameController;
    case 'קרטינג':
      return PhosphorIconsRegular.car;
    case 'פארק מים':
      return PhosphorIconsRegular.waves;
    case "ג'ימבורי":
      return PhosphorIconsRegular.baby;
    case 'תפעול':
      return PhosphorIconsRegular.wrench;
    default:
      return PhosphorIconsRegular.briefcase;
  }
}

/// Maps Hebrew department identifiers (stored in Firestore) to localized display names.
String getLocalizedDepartmentName(String hebrewName, AppLocalizations l10n) {
  switch (hebrewName) {
    case 'פארק חבלים':
      return l10n.deptRopes;
    case 'פיינטבול':
      return l10n.deptPaintball;
    case 'קרטינג':
      return l10n.deptCarting;
    case 'פארק מים':
      return l10n.deptWaterPark;
    case "ג'ימבורי":
      return l10n.deptJimbory;
    case 'תפעול':
      return l10n.deptOperations;
    default:
      return hebrewName;
  }
}
