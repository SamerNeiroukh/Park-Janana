import 'package:flutter/material.dart';

class UserSummaryCard extends StatelessWidget {
  final String userName;
  final String profileUrl;
  final int daysWorked;
  final double totalHours;
  final String month;

  const UserSummaryCard({
    super.key,
    required this.userName,
    required this.profileUrl,
    required this.daysWorked,
    required this.totalHours,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: profileUrl.isNotEmpty
                  ? NetworkImage(profileUrl)
                  : const AssetImage('assets/images/default_profile.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    month,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              children: [
                Text(
                  '$daysWorked ימים',
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${totalHours.toStringAsFixed(1)} שעות',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
