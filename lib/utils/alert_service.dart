import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';

class AlertService {
  /// Show an info message
  static void info(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppColors.primary,
      icon: Icons.info_outline,
    );
  }

  /// Show a success message
  static void success(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  /// Show a warning message
  static void warning(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppColors.secondaryYellow,
      textColor: Colors.black87,
      icon: Icons.warning_outlined,
    );
  }

  /// Show an error message
  static void error(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  /// Show a confirmation dialog
  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'אישור',
    String cancelText = 'ביטול',
    Color? confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: AppTheme.sectionTitle,
            textAlign: TextAlign.right,
          ),
          content: Text(
            message,
            style: AppTheme.bodyText,
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: AppTheme.secondaryButtonTextStyle,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: confirmColor ?? AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Private method to show standardized snack bars
  static void _showSnackBar(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppTheme.bodyText.copyWith(color: textColor),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}