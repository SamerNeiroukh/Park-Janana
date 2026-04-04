import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/constants/app_strings.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
//
// Purely visual — navigation is handled by main.dart's 6-second delay so
// there is no navigation logic here. This avoids the auth-state race condition
// that the previous implementation had.
//
// Animation layers:
//   1. Background  — hero image + dark gradient + ambient particles (loop)
//   2. Logo        — spring scale-in + fade-in, pulsing glow ring (loop)
//   3. Rotating arc ring around logo (loop)
//   4. App title   — slide-up + fade
//   5. Subtitle    — fade
//   6. Loading dots — three staggered sin-wave pulses (loop)
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── One-shot entrance (5.2 s) ─────────────────────────────────────────────
  late final AnimationController _entranceController;

  // ── Infinite loops ────────────────────────────────────────────────────────
  late final AnimationController _particleController; // 9 s — background orbs
  late final AnimationController _pulseController;    // 1.8 s — logo glow
  late final AnimationController _rotateController;   // 2.8 s — arc ring

  // ── Entrance animations ───────────────────────────────────────────────────
  late final Animation<double> _bgFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _ringFade;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 5200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat();

    // ── Background fade-in: 0.00 → 0.20 ──────────────────────────────────
    _bgFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.00, 0.20, curve: Curves.easeIn),
    );

    // ── Logo: 0.00 → 0.45 ─────────────────────────────────────────────────
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.00, 0.42, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.00, 0.48, curve: Curves.elasticOut),
      ),
    );

    // ── Arc ring: 0.18 → 0.50 ─────────────────────────────────────────────
    _ringFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.50, curve: Curves.easeIn),
    );

    // ── Title: 0.35 → 0.65 ────────────────────────────────────────────────
    _titleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeIn),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.55),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
    ));

    // ── Subtitle: 0.48 → 0.72 ─────────────────────────────────────────────
    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.48, 0.72, curve: Curves.easeIn),
    );

    // ── Loading dots: 0.62 → 0.82 ─────────────────────────────────────────
    _dotsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.62, 0.82, curve: Curves.easeIn),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Layer 1: animated background ──────────────────────────────────
          FadeTransition(
            opacity: _bgFade,
            child: _SplashBackground(particleController: _particleController),
          ),

          // ── Layer 2: content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: size.height * 0.14),

                // ── Logo + ring ──────────────────────────────────────────────
                SizedBox(
                  width: size.width * 0.52,
                  height: size.width * 0.52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Rotating arc ring
                      FadeTransition(
                        opacity: _ringFade,
                        child: AnimatedBuilder(
                          animation: _rotateController,
                          builder: (_, _) => CustomPaint(
                            painter: _ArcRingPainter(
                              rotation: _rotateController.value * 2 * math.pi,
                            ),
                            size: Size.square(size.width * 0.52),
                          ),
                        ),
                      ),

                      // Pulsing glow ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, _) {
                          final glow = 0.18 + 0.22 * _pulseController.value;
                          final spread = 2.0 + 8.0 * _pulseController.value;
                          return Container(
                            width: size.width * 0.40,
                            height: size.width * 0.40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue
                                      .withValues(alpha: glow),
                                  blurRadius: 40,
                                  spreadRadius: spread,
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      // Logo image
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Container(
                            width: size.width * 0.38,
                            height: size.width * 0.38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.09),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Image.asset(
                              AppConstants.parkLogo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.05),

                // ── App title ────────────────────────────────────────────────
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Text(
                      AppStrings.appTitle,
                      textAlign: TextAlign.center,
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 42,
                        shadows: const [
                          Shadow(
                            color: AppColors.primaryBlue,
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Subtitle ─────────────────────────────────────────────────
                FadeTransition(
                  opacity: _subtitleFade,
                  child: Text(
                    AppLocalizations.of(context).employeeManagementSystem,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: AppConstants.defaultFontFamily,
                      color: Colors.white.withValues(alpha: 0.55),
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),

                const Spacer(),

                // ── Loading dots ─────────────────────────────────────────────
                FadeTransition(
                  opacity: _dotsFade,
                  child: _LoadingDots(pulseController: _pulseController),
                ),

                SizedBox(height: size.height * 0.07),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background: hero image + dark gradient + ambient particles
// ─────────────────────────────────────────────────────────────────────────────

class _SplashBackground extends StatelessWidget {
  final AnimationController particleController;

  const _SplashBackground({required this.particleController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AppConstants.teamImage, fit: BoxFit.cover),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xE6000000),
                Color(0xA0001020),
                Color(0xF5001830),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: particleController,
          builder: (_, _) => CustomPaint(
            painter: _ParticlePainter(progress: particleController.value),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Rotating arc ring painted around the logo
// ─────────────────────────────────────────────────────────────────────────────

class _ArcRingPainter extends CustomPainter {
  final double rotation;

  const _ArcRingPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Outer dim track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Main sweeping arc (240°)
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: rotation,
        endAngle: rotation + (4 * math.pi / 3),
        colors: [
          AppColors.primaryBlue.withValues(alpha: 0.0),
          AppColors.primaryBlue.withValues(alpha: 0.85),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      rotation,
      4 * math.pi / 3,
      false,
      arcPaint,
    );

    // Bright leading dot at the arc tip
    final tipAngle = rotation + 4 * math.pi / 3;
    final tipX = center.dx + radius * math.cos(tipAngle);
    final tipY = center.dy + radius * math.sin(tipAngle);

    final dotPaint = Paint()
      ..color = AppColors.primaryBlue
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(tipX, tipY), 4, dotPaint);

    final dotCorePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(tipX, tipY), 2, dotCorePaint);
  }

  @override
  bool shouldRepaint(_ArcRingPainter old) => old.rotation != rotation;
}

// ─────────────────────────────────────────────────────────────────────────────
// Three staggered pulsing loading dots
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingDots extends StatelessWidget {
  final AnimationController pulseController;

  const _LoadingDots({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Each dot is offset by 120° in the sin cycle
            final phase = i * (2 * math.pi / 3);
            final t = pulseController.value * 2 * math.pi + phase;
            final scale = 0.5 + 0.5 * ((math.sin(t) + 1) / 2);
            final opacity = 0.3 + 0.7 * ((math.sin(t) + 1) / 2);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 8 * scale,
              height: 8 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(alpha: opacity),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(alpha: opacity * 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient floating particles — same visual language as WelcomeScreen
// ─────────────────────────────────────────────────────────────────────────────

class _ParticlePainter extends CustomPainter {
  final double progress;

  const _ParticlePainter({required this.progress});

  static const List<List<double>> _particles = [
    [0.08, 0.12, 55, 0.050, 0.28, 0.0],
    [0.88, 0.10, 68, 0.040, 0.18, 1.1],
    [0.50, 0.32, 36, 0.060, 0.42, 2.3],
    [0.15, 0.58, 46, 0.038, 0.22, 0.7],
    [0.78, 0.52, 40, 0.055, 0.33, 3.5],
    [0.35, 0.80, 58, 0.032, 0.25, 1.8],
    [0.92, 0.84, 28, 0.070, 0.50, 4.2],
    [0.60, 0.92, 50, 0.038, 0.20, 2.9],
    [0.25, 0.96, 34, 0.052, 0.38, 0.4],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final angle = 2 * math.pi * progress * p[4] + p[5];
      final dx = math.cos(angle) * 12;
      final dy = math.sin(angle) * 18;
      final center = Offset(size.width * p[0] + dx, size.height * p[1] + dy);

      canvas.drawCircle(
        center,
        p[2],
        Paint()
          ..color = Colors.white.withValues(alpha: p[3])
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
      canvas.drawCircle(
        center,
        p[2] * 0.18,
        Paint()
          ..color = AppColors.primaryBlue.withValues(alpha: p[3] * 1.8)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
