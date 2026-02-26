import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Compact metrics status panel shown below the top bar.
///
/// Displays current date, work stats (days + hours), weather chip,
/// and department chip in a single horizontal white card.
class MetricsStatusPanel extends StatelessWidget {
  final String currentDate;
  final int daysWorked;
  final double hoursWorked;
  final String? weatherDescription;
  final String? temperature;
  final String? department;

  const MetricsStatusPanel({
    super.key,
    required this.currentDate,
    required this.daysWorked,
    required this.hoursWorked,
    this.weatherDescription,
    this.temperature,
    this.department,
  });

  String _weatherEmoji(String d) {
    if (d.contains('בהיר') || d.contains('שמש')) return '☀️';
    if (d.contains('מעונן חלקית')) return '🌤️';
    if (d.contains('מעונן')) return '☁️';
    if (d.contains('גשם')) return '🌧️';
    if (d.contains('סערה')) return '⛈️';
    if (d.contains('שלג')) return '❄️';
    if (d.contains('ערפל')) return '🌫️';
    if (d.contains('רוחות')) return '💨';
    return '🌡️';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Date + dept chip ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    if (department != null && department!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          department!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4F46E5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Stat chips ────────────────────────────────────────
              _StatChip(
                value: '$daysWorked',
                label: 'ימים',
                color: const Color(0xFF4F46E5),
              ),
              const SizedBox(width: 8),
              _StatChip(
                value: hoursWorked.toStringAsFixed(1),
                label: "שע'",
                color: const Color(0xFF7C3AED),
              ),

              // ── Weather chip ──────────────────────────────────────
              if (weatherDescription != null && temperature != null) ...[
                const SizedBox(width: 8),
                _WeatherChip(
                  emoji: _weatherEmoji(weatherDescription!),
                  temp: temperature!,
                ),
              ],
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, curve: Curves.easeOut)
        .slideY(begin: 0.04, end: 0, duration: 350.ms, curve: Curves.easeOut);
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherChip extends StatelessWidget {
  final String emoji;
  final String temp;

  const _WeatherChip({required this.emoji, required this.temp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$emoji $temp°',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF16A34A),
        ),
      ),
    );
  }
}
