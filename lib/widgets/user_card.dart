import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:park_janana/screens/home/personal_area_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserCard extends StatelessWidget {
  final String userName;
  final String profilePictureUrl;
  final String currentDate;
  final int daysWorked;
  final double hoursWorked;
  final String? weatherDescription;
  final String? temperature;
  final String? weatherIcon;
  final VoidCallback? onProfileUpdated; // ✅ NEW

  const UserCard({
    super.key,
    required this.userName,
    required this.profilePictureUrl,
    required this.currentDate,
    required this.daysWorked,
    required this.hoursWorked,
    this.weatherDescription,
    this.temperature,
    this.weatherIcon,
    this.onProfileUpdated, // ✅ NEW
  });

  @override
  Widget build(BuildContext context) {
    final String emoji = _mapDescriptionToEmoji(weatherDescription ?? '');

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFFF8C00),
                      Color.fromARGB(255, 63, 163, 251),
                      Color(0xFFFF0000),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.white.withOpacity(0.05),
                      ),
                    ),
                    if (temperature != null && weatherDescription != null)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            '$emoji $temperature°C | $weatherDescription',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 70.0),
                        child: Column(
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'SuezOne',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currentDate,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: 0,
              right: 0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromARGB(255, 255, 195, 64),
                        width: 5,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonalAreaScreen(uid: uid),
                          ),
                        ).then((_) {
                          if (onProfileUpdated != null) {
                            onProfileUpdated!(); // ✅ Call to refresh
                          }
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundImage: NetworkImage(profilePictureUrl),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 65),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('', 'ימים שעבדת', daysWorked.toString()),
              _buildStatItem('', 'שעות שעבדת', hoursWorked.toStringAsFixed(1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$emoji $label',
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _mapDescriptionToEmoji(String description) {
    final desc = description.trim();
    if (desc.contains('בהיר') || desc.contains('שמש')) return '☀️';
    if (desc.contains('מעונן חלקית')) return '🌤️';
    if (desc.contains('מעונן')) return '☁️';
    if (desc.contains('גשם')) return '🌧️';
    if (desc.contains('סערה')) return '⛈️';
    if (desc.contains('שלג')) return '❄️';
    if (desc.contains('ערפל')) return '🌫️';
    if (desc.contains('רוחות')) return '💨';
    return '🌡️';
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 40,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
