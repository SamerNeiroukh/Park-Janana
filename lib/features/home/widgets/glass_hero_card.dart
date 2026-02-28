import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/attendance/models/attendance_model.dart';
import 'package:park_janana/features/attendance/services/clock_service.dart';
import 'package:park_janana/core/utils/location_utils.dart';

// ── Clock geometry ────────────────────────────────────────────────────────────
const double _kFace = 126.0;
const double _kRing = 154.0;

// ── Color tokens ──────────────────────────────────────────────────────────────
const _kSecondIdle   = Color(0xFFFBBF24); // amber  — idle second hand
const _kSecondActive = Color(0xFF4ADE80); // green  — active second hand
const _kArcIn        = Color(0xFF4ADE80); // green arc while clocking IN
const _kArcOut       = Color(0xFFF87171); // red   arc while clocking OUT

// ── Quotes (rotate every 10 s when idle) ──────────────────────────────────────
const _kQuotes = [
  '! היום זו הזדמנות חדשה להצטיין',
  '! תן את המיטב שלך בפארק היום',
  'אתה חלק חשוב בצוות שלנו 💪',
  'כל משמרת היא הזדמנות להשפיע ✨',
  'תשמור על חיוך – זה מדבק 😄',
];

// ═════════════════════════════════════════════════════════════════════════════
//  GlassHeroCard  — merged greeting + clock card
// ═════════════════════════════════════════════════════════════════════════════

class GlassHeroCard extends StatefulWidget {
  final String userName;
  final int daysWorked;
  final double hoursWorked;
  final String? weatherDescription;
  final String? temperature;
  final String? department;
  final IconData roleIcon;

  /// Fired after every successful clock-in / clock-out so the parent can
  /// refresh dependent state (e.g. UserProvider.loadWorkStats).
  final VoidCallback? onClockComplete;

  const GlassHeroCard({
    super.key,
    required this.userName,
    required this.daysWorked,
    required this.hoursWorked,
    this.weatherDescription,
    this.temperature,
    this.department,
    required this.roleIcon,
    this.onClockComplete,
  });

  @override
  State<GlassHeroCard> createState() => _GlassHeroCardState();
}

class _GlassHeroCardState extends State<GlassHeroCard>
    with TickerProviderStateMixin {

  // ── Attendance state ───────────────────────────────────────────────────────
  final ClockService _clockService = ClockService();
  AttendanceRecord? _session;
  bool _loading = true;
  bool _busy    = false;

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _clockTimer;
  Timer? _elapsedTimer;
  Timer? _quoteTimer;
  DateTime _now     = DateTime.now();
  Duration _elapsed = Duration.zero;
  int _quoteIdx     = 0;

  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _ringCtrl;    // 0→1 ring fill on long-press
  late final AnimationController _burstCtrl;   // success micro-burst scale
  late final AnimationController _breatheCtrl; // idle gentle breathe

  bool _fired = false;
  bool _h25 = false, _h50 = false, _h75 = false;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )
      ..addListener(_onRingTick)
      ..addStatusListener(_onRingStatus);

    _burstCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _breatheCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1), (_) { if (mounted) setState(() => _now = DateTime.now()); });
    _quoteTimer = Timer.periodic(
      const Duration(seconds: 10), (_) { if (mounted) setState(() => _quoteIdx = (_quoteIdx + 1) % _kQuotes.length); });

    _fetchSession();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _elapsedTimer?.cancel();
    _quoteTimer?.cancel();
    _ringCtrl.dispose();
    _burstCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  // ── Elapsed tracking ──────────────────────────────────────────────────────

  void _startElapsed() {
    _elapsedTimer?.cancel();
    if (_session == null) return;
    _elapsed = DateTime.now().difference(_session!.clockIn);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session != null) {
        setState(() => _elapsed = DateTime.now().difference(_session!.clockIn));
      } else {
        _elapsedTimer?.cancel();
      }
    });
  }

  // ── Long-press ring callbacks ──────────────────────────────────────────────

  void _onRingTick() {
    final v = _ringCtrl.value;
    if (!_h25 && v >= 0.25) { _h25 = true; HapticFeedback.selectionClick(); }
    if (!_h50 && v >= 0.50) { _h50 = true; HapticFeedback.selectionClick(); }
    if (!_h75 && v >= 0.75) { _h75 = true; HapticFeedback.selectionClick(); }
  }

  void _onRingStatus(AnimationStatus s) {
    if (s == AnimationStatus.completed && !_fired) {
      _fired = true;
      HapticFeedback.heavyImpact();
      _burstCtrl.forward(from: 0).then((_) => _burstCtrl.reverse());
      _handleAction();
    }
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (_busy || _loading) return;
    _fired = false;
    _h25 = _h50 = _h75 = false;
    HapticFeedback.lightImpact();
    _ringCtrl.forward(from: 0);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_fired) _ringCtrl.animateBack(0, curve: Curves.easeOut);
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _fetchSession() async {
    try {
      final s = await _clockService.getOngoingClockIn();
      if (!mounted) return;
      setState(() { _session = s; _loading = false; _now = DateTime.now(); });
      if (_session != null) _startElapsed();
    } catch (e) {
      debugPrint('GlassHeroCard _fetchSession: $e');
      if (mounted) setState(() { _session = null; _loading = false; });
    }
  }

  Future<void> _handleAction() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final name       = FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';
      final insidePark = await LocationUtils.isInsidePark();
      final clockingIn = _session == null;

      if (!insidePark && mounted) {
        final ok = await _showLocationWarning(clockingIn);
        if (ok != true) return;
      }

      if (!mounted) return;

      if (_session == null) {
        await _clockService.clockIn(name);
      } else {
        await _clockService.clockOut();
      }
      await _fetchSession();
      widget.onClockComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('שגיאה בדיווח נוכחות: $e', textAlign: TextAlign.right),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _ringCtrl.animateBack(0, curve: Curves.easeOut);
        _fired = false;
      }
    }
  }

  Future<bool?> _showLocationWarning(bool clockingIn) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Location',
      barrierColor: Colors.black54.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, __) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.85,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [AppColors.salmon, AppColors.darkRed], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.location_off_rounded, size: 48, color: Colors.white),
                ),
                const SizedBox(height: 22),
                const Text('אינך נמצא בגבולות הפארק', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                const SizedBox(height: 12),
                Text('אתה מנסה ${clockingIn ? 'להתחבר' : 'להתנתק'} מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4, color: Colors.black54)),
                const SizedBox(height: 28),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300], foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0, minimumSize: const Size(100, 48)),
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('לא', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0, backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                        minimumSize: const Size(100, 48)),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.darkRed, AppColors.salmon], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        child: const Text('כן', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) {
        final v = Curves.easeInOut.transform(anim.value);
        return Opacity(opacity: v, child: Transform.scale(scale: v, child: child));
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5)  return 'לילה טוב,';
    if (h < 12) return 'בוקר טוב,';
    if (h < 17) return 'צהריים טובים,';
    if (h < 21) return 'ערב טוב,';
    return 'לילה טוב,';
  }

  String _weatherEmoji(String d) {
    if (d.contains('בהיר') || d.contains('שמש')) return '☀️';
    if (d.contains('מעונן חלקית')) return '🌤️';
    if (d.contains('מעונן'))       return '☁️';
    if (d.contains('גשם'))         return '🌧️';
    if (d.contains('סערה'))        return '⛈️';
    if (d.contains('שלג'))         return '❄️';
    if (d.contains('ערפל'))        return '🌫️';
    if (d.contains('רוחות'))       return '💨';
    return '🌡️';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final active   = _session != null;
    final arcColor = active ? _kArcOut : _kArcIn;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF6D28D9)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4338CA).withOpacity(0.48),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Decorative ambient circles ────────────────────────────────
            Positioned(top: -36, left: -36,    child: _Circle(120, Colors.white.withOpacity(0.055))),
            Positioned(bottom: -50, right: -28, child: _Circle(160, Colors.white.withOpacity(0.040))),
            Positioned(top: 22, left: 100,      child: _Circle(56,  Colors.white.withOpacity(0.045))),
            Positioned(bottom: 60, left: 30,    child: _Circle(28,  Colors.white.withOpacity(0.065))),

            // ── Main content ──────────────────────────────────────────────
            Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // ── 1. Top row ─────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + greeting + dept
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_greeting(), style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.60),
                              )),
                              const SizedBox(height: 3),
                              Text(
                                widget.userName.split(' ').first,
                                style: const TextStyle(
                                  fontSize: 27, fontWeight: FontWeight.w800,
                                  color: Colors.white, height: 1.1,
                                ),
                              ),
                              if (widget.department != null && widget.department!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 7),
                                  child: _DeptChip(widget.department!),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Role icon badge + active status dot
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 54, height: 54,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white.withOpacity(0.18), width: 1),
                              ),
                              child: Icon(widget.roleIcon, size: 26, color: Colors.white.withOpacity(0.92)),
                            ),
                            // Green dot when clocked in
                            if (active)
                              Positioned(
                                right: -3, bottom: -3,
                                child: Container(
                                  width: 14, height: 14,
                                  decoration: BoxDecoration(
                                    color: _kSecondActive,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFF3730A3), width: 2),
                                    boxShadow: [BoxShadow(color: _kSecondActive.withOpacity(0.5), blurRadius: 6)],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // ── 2. Divider ─────────────────────────────────────────
                    Container(height: 1, color: Colors.white.withOpacity(0.12)),

                    const SizedBox(height: 22),

                    // ── 3. Clock ───────────────────────────────────────────
                    Center(
                      child: _loading
                          ? SizedBox(
                              height: _kRing,
                              child: Center(child: SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white.withOpacity(0.45)),
                              )),
                            )
                          : GestureDetector(
                              onLongPressStart: _onLongPressStart,
                              onLongPressEnd:   _onLongPressEnd,
                              child: AnimatedBuilder(
                                animation: Listenable.merge([_ringCtrl, _burstCtrl, _breatheCtrl]),
                                builder: (_, __) {
                                  final burst   = sin(_burstCtrl.value * pi) * 0.10;
                                  final breathe = active ? 0.0 : _breatheCtrl.value * 0.022;
                                  return Transform.scale(
                                    scale: 1.0 + burst + breathe,
                                    child: SizedBox(
                                      width: _kRing, height: _kRing,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          CustomPaint(
                                            size: const Size(_kRing, _kRing),
                                            painter: _RingPainter(progress: _ringCtrl.value, color: arcColor),
                                          ),
                                          CustomPaint(
                                            size: const Size(_kFace, _kFace),
                                            painter: _ClockPainter(now: _now, active: active),
                                          ),
                                          if (_busy)
                                            SizedBox(width: _kFace, height: _kFace,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2, color: Colors.white.withOpacity(0.70)),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    // ── 4. Elapsed timer OR motivational quote ─────────────
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.25), end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: active
                            ? _ActiveInfo(
                                key: const ValueKey('active'),
                                elapsed: _elapsed,
                                clockInTime: _session!.clockIn,
                              )
                            : _QuoteText(
                                key: ValueKey(_quoteIdx),
                                text: _kQuotes[_quoteIdx],
                              ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    // ── 5. Instruction hint ────────────────────────────────
                    Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          active ? 'לחיצה ארוכה לסיום משמרת' : 'לחיצה ארוכה להתחיל משמרת',
                          key: ValueKey(active),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.50),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── 6. Divider ─────────────────────────────────────────
                    Container(height: 1, color: Colors.white.withOpacity(0.12)),

                    const SizedBox(height: 18),

                    // ── 7. Stats strip ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(child: _Stat(
                          icon: Icons.calendar_today_rounded,
                          value: '${widget.daysWorked}',
                          label: 'ימים',
                        )),
                        Container(width: 1, height: 44, color: Colors.white.withOpacity(0.14)),
                        Expanded(child: _Stat(
                          icon: Icons.access_time_rounded,
                          value: widget.hoursWorked.toStringAsFixed(1),
                          label: "שע'",
                        )),
                        if (widget.weatherDescription != null && widget.temperature != null) ...[
                          Container(width: 1, height: 44, color: Colors.white.withOpacity(0.14)),
                          Expanded(child: _WeatherStat(
                            emoji: _weatherEmoji(widget.weatherDescription!),
                            temp: widget.temperature!,
                          )),
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

// ═════════════════════════════════════════════════════════════════════════════
//  Small private widgets
// ═════════════════════════════════════════════════════════════════════════════

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

class _DeptChip extends StatelessWidget {
  final String label;
  const _DeptChip(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.14),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withOpacity(0.20)),
    ),
    child: Text(label, style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
    )),
  );
}

class _ActiveInfo extends StatelessWidget {
  final Duration elapsed;
  final DateTime clockInTime;
  const _ActiveInfo({super.key, required this.elapsed, required this.clockInTime});

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final str   = '${two(elapsed.inHours)}:${two(elapsed.inMinutes.remainder(60))}:${two(elapsed.inSeconds.remainder(60))}';
    final since = 'מאז ${two(clockInTime.hour)}:${two(clockInTime.minute)}';
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(str, style: const TextStyle(
        fontSize: 24, fontWeight: FontWeight.w700,
        color: _kSecondActive, letterSpacing: 3.5, height: 1,
      )),
      const SizedBox(height: 4),
      Text(since, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.55), letterSpacing: 0.5,
      )),
    ]);
  }
}

class _QuoteText extends StatelessWidget {
  final String text;
  const _QuoteText({super.key, required this.text});
  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 12.5, fontWeight: FontWeight.w500,
      color: Colors.white.withOpacity(0.65), height: 1.4,
    ),
  );
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 18, color: Colors.white.withOpacity(0.65)),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0,
      )),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.50),
      )),
    ],
  );
}

class _WeatherStat extends StatelessWidget {
  final String emoji;
  final String temp;
  const _WeatherStat({required this.emoji, required this.temp});
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(height: 4),
      Text('$temp°', style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0,
      )),
      const SizedBox(height: 3),
      Text('מזג אוויר', style: TextStyle(
        fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.50),
      )),
    ],
  );
}

// ═════════════════════════════════════════════════════════════════════════════
//  Analog clock face CustomPainter
// ═════════════════════════════════════════════════════════════════════════════

class _ClockPainter extends CustomPainter {
  final DateTime now;
  final bool active;
  const _ClockPainter({required this.now, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Face fill
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.11)
      ..style = PaintingStyle.fill);

    // Inner glow when active
    if (active) {
      canvas.drawCircle(c, r - 1, Paint()
        ..color = _kSecondActive.withOpacity(0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }

    // Border ring
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Tick marks
    for (int i = 0; i < 60; i++) {
      final angle = i * pi / 30 - pi / 2;
      final isHour = i % 5 == 0;
      _line(canvas,
        Offset(c.dx + (r - 3) * cos(angle), c.dy + (r - 3) * sin(angle)),
        Offset(c.dx + (r - 3 - (isHour ? 9.0 : 4.0)) * cos(angle),
               c.dy + (r - 3 - (isHour ? 9.0 : 4.0)) * sin(angle)),
        Colors.white.withOpacity(isHour ? 0.90 : 0.30),
        isHour ? 2.5 : 1.1,
      );
    }

    // Hour hand
    final hA = (now.hour % 12 + now.minute / 60) * pi / 6 - pi / 2;
    _drawHand(canvas, c, hA, r * 0.46, 3.5, Colors.white);

    // Minute hand
    final mA = (now.minute + now.second / 60) * pi / 30 - pi / 2;
    _drawHand(canvas, c, mA, r * 0.65, 2.2, Colors.white);

    // Second hand + tail
    final sA = now.second * pi / 30 - pi / 2;
    final sc = active ? _kSecondActive : _kSecondIdle;
    _drawHand(canvas, c, sA,        r * 0.73, 1.3, sc);
    _drawHand(canvas, c, sA + pi,   r * 0.20, 1.3, sc);

    // Center caps
    canvas.drawCircle(c, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(c, 3.0, Paint()..color = sc);
  }

  void _drawHand(Canvas canvas, Offset c, double angle, double len, double w, Color color) {
    _line(canvas, c, Offset(c.dx + len * cos(angle), c.dy + len * sin(angle)), color, w);
  }

  void _line(Canvas canvas, Offset a, Offset b, Color color, double w) {
    canvas.drawLine(a, b, Paint()
      ..color = color
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_ClockPainter old) =>
      old.now.second != now.second || old.now.minute != now.minute || old.active != active;
}

// ═════════════════════════════════════════════════════════════════════════════
//  Long-press ring CustomPainter
// ═════════════════════════════════════════════════════════════════════════════

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 6;

    // Ghost track
    canvas.drawCircle(c, r, Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5);

    if (progress <= 0) return;

    // Glow
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false,
      Paint()
        ..color = color.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));

    // Crisp arc
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -pi / 2, 2 * pi * progress, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round);

    // Leading dot
    if (progress > 0.01) {
      final tip = Offset(
        c.dx + r * cos(-pi / 2 + 2 * pi * progress),
        c.dy + r * sin(-pi / 2 + 2 * pi * progress),
      );
      canvas.drawCircle(tip, 4.5, Paint()..color = Colors.white);
      canvas.drawCircle(tip, 7.0, Paint()
        ..color = color.withOpacity(0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
