import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';

class DashboardHeroCard extends StatelessWidget {
  final String userName;
  final String profilePictureUrl;
  final String role;
  final List<String> licensedDepartments;
  final int daysWorked;
  final double hoursWorked;
  final String? weatherDescription;
  final String? temperature;
  final String currentDate;
  final VoidCallback onProfileTap;

  const DashboardHeroCard({
    super.key,
    required this.userName,
    required this.profilePictureUrl,
    required this.role,
    required this.licensedDepartments,
    required this.daysWorked,
    required this.hoursWorked,
    this.weatherDescription,
    this.temperature,
    required this.currentDate,
    required this.onProfileTap,
  });

  LinearGradient get _heroGradient => const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );

  String _roleLabel() {
    switch (role) {
      case 'manager':
        return 'מנהל';
      case 'owner':
        return 'בעלים';
      default:
        return 'עובד';
    }
  }

  String _weatherEmoji(String d) {
    if (d.contains('בהיר') || d.contains('שמש')) return '☀️';
    if (d.contains('מעונן חלקית')) return '🌤️';
    if (d.contains('מעונן')) return '☁️';
    if (d.contains('גשם')) return '🌧️';
    if (d.contains('סערה')) return '⛈️';
    if (d.contains('שלג')) return '❄️';
    if (d.contains('ערפל')) return '🌫️';
    return '🌡️';
  }

  @override
  Widget build(BuildContext context) {
    final dept =
        licensedDepartments.isNotEmpty ? licensedDepartments.first : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: _heroGradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.18),
              blurRadius: 32,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // subtle glass highlight layer
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),

              Directionality(
                textDirection: TextDirection.rtl,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                _AvatarRing(
                                  imageUrl: profilePictureUrl,
                                  onTap: onProfileTap,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _roleLabel(),
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (dept.isNotEmpty) ...[
                                        const SizedBox(height: 3),
                                        Text(
                                          dept,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.65),
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _StatPill(
                                value: hoursWorked.toStringAsFixed(1),
                                label: 'שעות',
                              ),
                              const SizedBox(height: 10),
                              _StatPill(
                                value: '$daysWorked',
                                label: 'ימים',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Divider(
                        color: Colors.white.withOpacity(0.25),
                        thickness: 1,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (weatherDescription != null && temperature != null)
                            _WeatherChip(
                              emoji: _weatherEmoji(weatherDescription!),
                              temp: temperature!,
                              desc: weatherDescription!,
                            ),
                          Text(
                            currentDate,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.06, end: 0);
  }
}

class _AvatarRing extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback onTap;

  const _AvatarRing({required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
        ),
        child: ProfileAvatar(
          imageUrl: imageUrl,
          radius: 30,
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;

  const _StatPill({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        '$value $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final String emoji;
  final String temp;
  final String desc;

  const _WeatherChip({
    required this.emoji,
    required this.temp,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Text(
        '$emoji  $temp°C · $desc',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
