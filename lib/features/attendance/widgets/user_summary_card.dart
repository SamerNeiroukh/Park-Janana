import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';

class UserSummaryCard extends StatelessWidget {
  final String userName;

  /// Legacy URL (fallback)
  final String profileUrl;

  /// NEW: Firebase Storage path (preferred)
  final String? profilePicturePath;

  final int daysWorked;
  final double totalHours;
  final String month;
  final VoidCallback? onTap;

  const UserSummaryCard({
    super.key,
    required this.userName,
    required this.profileUrl,
    this.profilePicturePath,
    required this.daysWorked,
    required this.totalHours,
    required this.month,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      child: Card(
        key: ValueKey('$userName-$month-$daysWorked-$totalHours'),
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                FutureBuilder<ImageProvider>(
                  future: ProfileImageProvider.resolve(
                    storagePath: profilePicturePath,
                    fallbackUrl: profileUrl,
                  ),
                  builder: (context, snapshot) {
                    return CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: snapshot.data,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        month,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$daysWorked ימים',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      '${totalHours.toStringAsFixed(1)} שעות',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
