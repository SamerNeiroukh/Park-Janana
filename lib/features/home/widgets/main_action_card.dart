import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Primary Focus Card — the single dominant action card on the home screen.
///
/// Design:
///  • Gradient #4F46E5 → #7C3AED (consistent across roles)
///  • CTA pill button inside (white, role-specific label)
///  • Icon container on left (RTL visual left)
///  • Rounded 24 corners, shadow blur ≤ 16
///  • Press scale 0.96
class MainActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const MainActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.ctaLabel = 'פתח',
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<MainActionCard> createState() => _MainActionCardState();
}

class _MainActionCardState extends State<MainActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Text + CTA pill ───────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.78),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // CTA pill (visual only — whole card is the tap target)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.ctaLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: widget.gradient.first,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_back_ios_rounded,
                                size: 11,
                                color: widget.gradient.first,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── Icon container (left in RTL) ───────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, curve: Curves.easeOut)
        .slideY(begin: 0.05, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}
