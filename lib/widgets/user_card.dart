import 'package:flutter/material.dart';

class UserCard extends StatelessWidget {
  final String userName;
  final String profilePictureUrl;
  final String currentDate;
  final int daysWorked;
  final int hoursWorked;

  const UserCard({
    super.key,
    required this.userName,
    required this.profilePictureUrl,
    required this.currentDate,
    required this.daysWorked,
    required this.hoursWorked,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4.0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 255, 140, 0).withOpacity(0.8), // Orange
              const Color.fromARGB(255, 63, 94, 251).withOpacity(0.8), // Blue
              const Color.fromARGB(255, 255, 0, 0).withOpacity(0.8), // Red
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // User Name and Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontFamily: 'SuezOne',
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  currentDate,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'ימים שעבדת: $daysWorked | שעות שעבדת: $hoursWorked',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16.0),
            // Profile Picture
            CircleAvatar(
              radius: 30.0,
              backgroundImage: NetworkImage(profilePictureUrl),
            ),
          ],
        ),
      ),
    );
  }
}
