import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';

class ErrorStateWidget extends StatelessWidget {
  final String errorMessage;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    required this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 80,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'שגיאה באתחול האפליקציה',
                      style: AppTheme.screenTitle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage,
                      style: AppTheme.bodyText.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    if (onRetry != null)
                      ElevatedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('נסה שוב'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'אם הבעיה נמשכת, אנא צור קשר עם התמיכה',
                      style: AppTheme.hintTextStyle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
