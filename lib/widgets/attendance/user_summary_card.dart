import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:park_janana/constants/app_theme.dart';

class UserSummaryCard extends StatelessWidget {
  final String userName;
  final String profileUrl;
  final int daysWorked;
  final double totalHours;
  final String month;
  final VoidCallback? onTap; // Optional tap handler

  const UserSummaryCard({
    super.key,
    required this.userName,
    required this.profileUrl,
    required this.daysWorked,
    required this.totalHours,
    required this.month,
    this.onTap,
  });

  ImageProvider _getProfileImage(String url) {
    return (url.isNotEmpty && url.startsWith('http'))
        ? CachedNetworkImageProvider(url)
        : const AssetImage('assets/images/default_profile.png');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeIn,
      child: Card(
        key: ValueKey('$userName-$month-$daysWorked-$totalHours'),
        elevation: 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _getProfileImage(profileUrl),
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
