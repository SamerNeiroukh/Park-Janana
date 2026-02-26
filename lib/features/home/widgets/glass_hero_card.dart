import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Immersive gradient hero card — greeting section only.
///
/// Shows a personalised greeting, department chip, role icon badge,
/// and live work-stats chips (days / hours / weather).
/// The primary CTA now lives in the horizontal action strip below.
class GlassHeroCard extends StatelessWidget {
  final String userName;
  final int daysWorked;
  final double hoursWorked;
  final String? weatherDescription;
  final String? temperature;
  final String? department;
  final IconData roleIcon;

  const GlassHeroCard({
    super.key,
    required this.userName,
    required this.daysWorked,
    required this.hoursWorked,
    this.weatherDescription,
    this.temperature,
    this.department,
    required this.roleIcon,
  });

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'לילה טוב,';
    if (h < 12) return 'בוקר טוב,';
    if (h < 17) return 'צהריים טובים,';
    if (h < 21) return 'ערב טוב,';
    return 'לילה טוב,';
  }

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
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF3730A3),
              Color(0xFF6D28D9),
              Color(0xFFA855F7),
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5B50E0).withOpacity(0.42),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decorative circles ──────────────────────────────
            Positioned(
                top: -32,
                left: -32,
                child: _DecorCircle(110, Colors.white.withOpacity(0.07))),
            Positioned(
                bottom: -44,
                right: -24,
                child: _DecorCircle(140, Colors.white.withOpacity(0.05))),
            Positioned(
                top: 18,
                left: 90,
                child: _DecorCircle(52, Colors.white.withOpacity(0.06))),
            Positioned(
                bottom: 28,
                left: 28,
                child: _DecorCircle(24, Colors.white.withOpacity(0.08))),

            // ── Content ─────────────────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Greeting row ───────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting(),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.72),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userName.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15,
                                ),
                              ),
                              if (department != null &&
                                  department!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 9, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withOpacity(0.16),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                      border: Border.all(
                                        color:
                                            Colors.white.withOpacity(0.20),
                                      ),
                                    ),
                                    child: Text(
                                      department!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Role icon badge
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.22),
                            ),
                          ),
                          child: Icon(roleIcon, size: 28, color: Colors.white),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Divider ────────────────────────────────
                    Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.14),
                    ),

                    const SizedBox(height: 14),

                    // ── Stats chips row ────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _GlassChip(
                            icon: Icons.calendar_today_rounded,
                            value: '$daysWorked',
                            label: 'ימים',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _GlassChip(
                            icon: Icons.access_time_rounded,
                            value: hoursWorked.toStringAsFixed(1),
                            label: "שע'",
                          ),
                        ),
                        if (weatherDescription != null &&
                            temperature != null) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: _GlassWeatherChip(
                              emoji: _weatherEmoji(weatherDescription!),
                              temp: temperature!,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 480.ms, curve: Curves.easeOut)
        .slideY(begin: 0.06, end: 0, duration: 480.ms, curve: Curves.easeOut);
  }
}

// ── Decorative circle ──────────────────────────────────────────────────────

class _DecorCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorCircle(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── Glass stat chip ────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _GlassChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: Colors.white.withOpacity(0.85)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Glass weather chip ─────────────────────────────────────────────────────

class _GlassWeatherChip extends StatelessWidget {
  final String emoji;
  final String temp;

  const _GlassWeatherChip({required this.emoji, required this.temp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            '$temp°',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'מזג אוויר',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.65),
            ),
          ),
        ],
      ),
    );
  }
}
