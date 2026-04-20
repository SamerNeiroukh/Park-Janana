import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:park_janana/features/auth/screens/login_screen.dart';
import 'package:park_janana/features/auth/screens/new_worker_screen.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WelcomeScreen — animated entry screen with staggered entrance, floating
// particles, and micro-interaction buttons. Navigation logic is unchanged.
// ─────────────────────────────────────────────────────────────────────────────

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _entranceController;
  late final AnimationController _particleController;
  late final AnimationController _shimmerController;

  // ── Logo ──────────────────────────────────────────────────────────────────
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // ── Title ─────────────────────────────────────────────────────────────────
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  // ── Subtitle ──────────────────────────────────────────────────────────────
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  // ── Buttons ───────────────────────────────────────────────────────────────
  late final Animation<double> _button1Fade;
  late final Animation<Offset> _button1Slide;
  late final Animation<double> _button2Fade;
  late final Animation<Offset> _button2Slide;

  // ── Divider line ──────────────────────────────────────────────────────────
  late final Animation<double> _dividerFade;

  @override
  void initState() {
    super.initState();

    // Entrance: plays once, 1900 ms total
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    );

    // Particles: infinite loop, 9 s per cycle
    _particleController = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat();

    // Shimmer on logo glow: 2.5 s loop
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat(reverse: true);

    // ── Logo: interval 0.00 – 0.45 ─────────────────────────────────────────
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.00, 0.45, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.00, 0.50, curve: Curves.elasticOut),
      ),
    );

    // ── Title: interval 0.20 – 0.60 ────────────────────────────────────────
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.60, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.20, 0.60, curve: Curves.easeOutCubic),
    ));

    // ── Subtitle: interval 0.28 – 0.65 ─────────────────────────────────────
    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.65, curve: Curves.easeIn),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.28, 0.65, curve: Curves.easeOutCubic),
    ));

    // ── Divider: interval 0.40 – 0.65 ──────────────────────────────────────
    _dividerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 0.65, curve: Curves.easeIn),
    );

    // ── Button 1: interval 0.48 – 0.78 ─────────────────────────────────────
    _button1Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.78, curve: Curves.easeIn),
    );
    _button1Slide = Tween<Offset>(
      begin: const Offset(0, 0.9),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.78, curve: Curves.easeOutCubic),
    ));

    // ── Button 2: interval 0.58 – 0.88 ─────────────────────────────────────
    _button2Fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.58, 0.88, curve: Curves.easeIn),
    );
    _button2Slide = Tween<Offset>(
      begin: const Offset(0, 0.9),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.58, 0.88, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  /// Unchanged navigation logic with slide-up page transition.
  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Layer 1: animated background ─────────────────────────────────
          _WelcomeBackground(particleController: _particleController),

          // ── Layer 2: content ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: size.height * 0.08),

                  // ── Animated logo ─────────────────────────────────────────
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _WelcomeLogo(shimmerController: _shimmerController),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Animated title ────────────────────────────────────────
                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Text(
                        AppLocalizations.of(context).appTitle,
                        textAlign: TextAlign.center,
                        style: AppTheme.titleStyle.copyWith(
                          fontSize: 40,
                          shadows: const [
                            Shadow(
                              color: AppColors.primaryBlue,
                              blurRadius: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Animated subtitle ─────────────────────────────────────
                  SlideTransition(
                    position: _subtitleSlide,
                    child: FadeTransition(
                      opacity: _subtitleFade,
                      child: const _WelcomeSubtitle(),
                    ),
                  ),

                  const Spacer(),

                  // ── Divider ───────────────────────────────────────────────
                  FadeTransition(
                    opacity: _dividerFade,
                    child: const _GlowDivider(),
                  ),

                  const SizedBox(height: 28),

                  // ── Button 1: Login ───────────────────────────────────────
                  SlideTransition(
                    position: _button1Slide,
                    child: FadeTransition(
                      opacity: _button1Fade,
                      child: _PressableButton(
                        label: AppLocalizations.of(context).loginButton,
                        color: AppColors.primaryBlue,
                        onPressed: () =>
                            _navigateToScreen(context, const LoginScreen()),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Button 2: New Worker ──────────────────────────────────
                  SlideTransition(
                    position: _button2Slide,
                    child: FadeTransition(
                      opacity: _button2Fade,
                      child: _PressableButton(
                        label: AppLocalizations.of(context).newWorkerButton,
                        color: AppColors.secondaryYellow,
                        onPressed: () =>
                            _navigateToScreen(context, const NewWorkerScreen()),
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.055),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background: team image + dark gradient overlay + floating particles
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeBackground extends StatelessWidget {
  final AnimationController particleController;

  const _WelcomeBackground({required this.particleController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Hero image
        Image.asset(
          AppConstants.teamImage,
          fit: BoxFit.cover,
        ),

        // Multi-stop dark gradient for depth and legibility
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xD9000000), // 85 % black — top
                Color(0x99001020), // 60 % dark navy — mid
                Color(0xF2001830), // 95 % dark navy — bottom
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),

        // Floating ambient particles
        AnimatedBuilder(
          animation: particleController,
          builder: (context, _) => CustomPaint(
            painter: _ParticlePainter(progress: particleController.value),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Logo: circular frosted-glass frame with pulsing glow
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeLogo extends StatelessWidget {
  final AnimationController shimmerController;

  const _WelcomeLogo({required this.shimmerController});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.42;

    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, child) {
        final glowOpacity =
            0.25 + 0.20 * shimmerController.value; // 0.25 → 0.45
        final spreadRadius = 4.0 + 6.0 * shimmerController.value;

        return Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.10),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: glowOpacity),
                blurRadius: 36,
                spreadRadius: spreadRadius,
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: child,
        );
      },
      child: Image.asset(
        AppConstants.parkLogo,
        fit: BoxFit.contain,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subtitle: static Hebrew welcome text
// ─────────────────────────────────────────────────────────────────────────────

class _WelcomeSubtitle extends StatelessWidget {
  const _WelcomeSubtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).welcomeSubtitle,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        fontFamily: AppConstants.defaultFontFamily,
        color: Colors.white.withValues(alpha: 0.65),
        letterSpacing: 2.0,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Glow divider between subtitle and buttons
// ─────────────────────────────────────────────────────────────────────────────

class _GlowDivider extends StatelessWidget {
  const _GlowDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.primaryBlue.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBlue.withValues(alpha: 0.8),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pressable button with scale micro-interaction on tap
// ─────────────────────────────────────────────────────────────────────────────

class _PressableButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _PressableButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _pressController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 7),
                spreadRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: AppTheme.buttonTextStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Particle painter: soft floating orbs for ambient depth
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;

  const _ParticlePainter({required this.progress});

  // Static particle definitions: (relX, relY, radius, opacity, speed, phase)
  static const List<List<double>> _particles = [
    [0.08, 0.12, 55, 0.055, 0.28, 0.0],
    [0.88, 0.10, 70, 0.045, 0.18, 1.1],
    [0.50, 0.30, 38, 0.065, 0.42, 2.3],
    [0.15, 0.55, 48, 0.040, 0.22, 0.7],
    [0.78, 0.50, 42, 0.060, 0.33, 3.5],
    [0.35, 0.78, 60, 0.035, 0.25, 1.8],
    [0.92, 0.82, 30, 0.075, 0.50, 4.2],
    [0.60, 0.90, 52, 0.040, 0.20, 2.9],
    [0.25, 0.95, 36, 0.055, 0.38, 0.4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final relX = p[0];
      final relY = p[1];
      final radius = p[2];
      final opacity = p[3];
      final speed = p[4];
      final phase = p[5];

      final angle = 2 * math.pi * progress * speed + phase;
      final dx = math.cos(angle) * 12;
      final dy = math.sin(angle) * 18;

      final center = Offset(
        size.width * relX + dx,
        size.height * relY + dy,
      );

      // Soft outer glow
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
      canvas.drawCircle(center, radius, glowPaint);

      // Bright inner core
      final corePaint = Paint()
        ..color = AppColors.primaryBlue.withValues(alpha: opacity * 1.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center, radius * 0.18, corePaint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
