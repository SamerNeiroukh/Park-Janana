import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import '../models/attendance_model.dart';
import '../services/clock_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:park_janana/core/utils/location_utils.dart';

// ── Color tokens (on the hero-card gradient background) ──────────────────────
const _kSecondHandIdle = Color(0xFFFBBF24); // amber
const _kSecondHandActive = Color(0xFF4ADE80); // green
const _kRingClockIn = Color(0xFF4ADE80); // green arc = clocking in
const _kRingClockOut = Color(0xFFF87171); // red  arc = clocking out
const _kClockSize = 96.0; // clock face diameter
const _kRingSize = 118.0; // outer ring diameter

// ═════════════════════════════════════════════════════════════════════════════
//  ClockInOutWidget
// ═════════════════════════════════════════════════════════════════════════════

class ClockInOutWidget extends StatefulWidget {
  /// Called after a successful clock-in or clock-out so the parent can
  /// refresh any dependent state (e.g. work-stats in UserProvider).
  final VoidCallback? onClockComplete;

  const ClockInOutWidget({super.key, this.onClockComplete});

  @override
  State<ClockInOutWidget> createState() => _ClockInOutWidgetState();
}

class _ClockInOutWidgetState extends State<ClockInOutWidget>
    with TickerProviderStateMixin {
  // ── Business logic ────────────────────────────────────────────────────────
  final ClockService _clockService = ClockService();
  AttendanceRecord? _ongoingSession;
  bool _loading = true;
  bool _actionInProgress = false;

  // ── Timers ────────────────────────────────────────────────────────────────
  Timer? _secondTimer;
  Timer? _elapsedTimer;
  DateTime _now = DateTime.now();
  Duration _elapsed = Duration.zero;

  // ── Animation controllers ─────────────────────────────────────────────────
  late final AnimationController _ringCtrl;   // long-press ring fill 0→1
  late final AnimationController _burstCtrl;  // success micro-burst
  late final AnimationController _breatheCtrl; // idle clock glow

  bool _autoClockOutDone = false;
  bool _actionFired = false;
  bool _haptic25 = false;
  bool _haptic50 = false;
  bool _haptic75 = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )
      ..addListener(_onRingTick)
      ..addStatusListener(_onRingStatus);

    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _startSecondTimer();
    _fetchSession();
  }

  @override
  void dispose() {
    _secondTimer?.cancel();
    _elapsedTimer?.cancel();
    _ringCtrl.dispose();
    _burstCtrl.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  // ── Timers ────────────────────────────────────────────────────────────────

  void _startSecondTimer() {
    _secondTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _autoClockOutDone = false;
    if (_ongoingSession != null) {
      _elapsed = DateTime.now().difference(_ongoingSession!.clockIn);
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && _ongoingSession != null) {
          final elapsed = DateTime.now().difference(_ongoingSession!.clockIn);
          setState(() => _elapsed = elapsed);
          if (!_autoClockOutDone && elapsed.inHours >= 16) {
            _autoClockOutDone = true;
            _elapsedTimer?.cancel();
            _autoClockOut();
          }
        } else {
          _elapsedTimer?.cancel();
        }
      });
    }
  }

  Future<void> _autoClockOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _ongoingSession == null) return;
    try {
      await _clockService.clockOut();
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('notifications')
          .add({
        'type': 'clockout_missed',
        'title': 'יציאה אוטומטית ממשמרת',
        'body': 'לא דיווחת יציאה לאחר 16 שעות – המערכת סיימה את המשמרת אוטומטית. פנה למנהל שלך.',
        'entityId': '',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _fetchSession();
      widget.onClockComplete?.call();
    } catch (e) {
      debugPrint('Auto clock-out error: $e');
    }
  }

  // ── Long-press ring callbacks ─────────────────────────────────────────────

  void _onRingTick() {
    final v = _ringCtrl.value;
    if (!_haptic25 && v >= 0.25) {
      _haptic25 = true;
      HapticFeedback.selectionClick();
    }
    if (!_haptic50 && v >= 0.50) {
      _haptic50 = true;
      HapticFeedback.selectionClick();
    }
    if (!_haptic75 && v >= 0.75) {
      _haptic75 = true;
      HapticFeedback.selectionClick();
    }
    // setState driven by AnimationBuilder — no extra call needed here
  }

  void _onRingStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_actionFired) {
      _actionFired = true;
      HapticFeedback.heavyImpact();
      _burstCtrl.forward(from: 0).then((_) => _burstCtrl.reverse());
      _handleAction();
    }
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (_actionInProgress || _loading) return;
    _actionFired = false;
    _haptic25 = _haptic50 = _haptic75 = false;
    HapticFeedback.lightImpact();
    _ringCtrl.forward(from: 0);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (!_actionFired) {
      _ringCtrl.animateBack(0, curve: Curves.easeOut);
    }
  }

  // ── Data fetching (UNCHANGED) ─────────────────────────────────────────────

  Future<void> _fetchSession() async {
    try {
      final session = await _clockService.getOngoingClockIn();
      if (!mounted) return;
      setState(() {
        _ongoingSession = session;
        _loading = false;
        _now = DateTime.now();
      });
      if (_ongoingSession != null) _startElapsedTimer();
    } catch (e) {
      debugPrint('Error fetching session: $e');
      if (mounted) setState(() { _ongoingSession = null; _loading = false; });
    }
  }

  // ── Action handler (UNCHANGED logic) ─────────────────────────────────────

  Future<void> _handleAction() async {
    if (_actionInProgress) return;

    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';
    bool? insidePark = await LocationUtils.isInsidePark();
    final isClockingIn = _ongoingSession == null;

    if (insidePark == null && mounted) {
      // Location service off or permission denied — ask user to enable it
      final enabled = await _showLocationRequiredDialog();
      if (!enabled || !mounted) {
        _ringCtrl.animateBack(0, curve: Curves.easeOut);
        return;
      }
      // Re-check after returning from settings
      insidePark = await LocationUtils.isInsidePark();
      if (insidePark == null && mounted) {
        _ringCtrl.animateBack(0, curve: Curves.easeOut);
        return;
      }
    }

    if (insidePark != true && mounted) {
      final confirm = await _showLocationWarning(isClockingIn);
      if (confirm != true) {
        if (mounted) _ringCtrl.animateBack(0, curve: Curves.easeOut);
        return;
      }
    }

    if (!mounted) return;
    setState(() => _actionInProgress = true);

    try {
      if (_ongoingSession == null) {
        await _clockService.clockIn(userName);
      } else {
        await _clockService.clockOut();
      }
      await _fetchSession();
      widget.onClockComplete?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text('שגיאה בדיווח נוכחות: $e',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    textAlign: TextAlign.right),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 20),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
        _ringCtrl.animateBack(0, curve: Curves.easeOut);
        _actionFired = false;
      }
    }
  }

  // ── Location required (service off / permission denied) ──────────────────

  Future<bool> _showLocationRequiredDialog() async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LocationRequired',
      barrierColor: Colors.black54.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.85,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [AppColors.salmon, AppColors.darkRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2)
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: const Icon(Icons.location_disabled_rounded,
                        size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'נדרשת גישה למיקום',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'כדי לדווח כניסה או יציאה ממשמרת יש לאפשר שירותי מיקום במכשיר.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.black54,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 0),
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('ביטול',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30)),
                              elevation: 0,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent),
                          onPressed: () async {
                            await Geolocator.openLocationSettings();
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          },
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [AppColors.darkRed, AppColors.salmon],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: const Text('הפעל מיקום',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15,
                                      color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, _, child) {
        final v = Curves.easeInOut.transform(anim.value);
        return Opacity(opacity: v, child: Transform.scale(scale: v, child: child));
      },
    );
    return result ?? false;
  }

  // ── Location warning (UNCHANGED) ─────────────────────────────────────────

  Future<bool?> _showLocationWarning(bool isClockingIn) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Location',
      barrierColor: Colors.black54.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.85,
            padding:
                const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                        colors: [AppColors.salmon, AppColors.darkRed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2)
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.location_off_rounded,
                      size: 48, color: Colors.white),
                ),
                const SizedBox(height: 22),
                const Text('אינך נמצא בגבולות הפארק',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87)),
                const SizedBox(height: 12),
                Text(
                    'אתה מנסה ${isClockingIn ? 'להתחבר' : 'להתנתק'} מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: Colors.black54)),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                          minimumSize: const Size(100, 48)),
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('לא',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 0,
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(100, 48)),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [AppColors.darkRed, AppColors.salmon],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                          child: const Text('כן',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, _, child) {
        final v = Curves.easeInOut.transform(anim.value);
        return Opacity(opacity: v, child: Transform.scale(scale: v, child: child));
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white54),
          ),
        ),
      );
    }

    final isClockedIn = _ongoingSession != null;
    final ringColor = isClockedIn ? _kRingClockOut : _kRingClockIn;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Analog clock + long-press ring ──────────────────────────────
          GestureDetector(
            onLongPressStart: _onLongPressStart,
            onLongPressEnd: _onLongPressEnd,
            child: AnimatedBuilder(
              animation: Listenable.merge([_ringCtrl, _burstCtrl, _breatheCtrl]),
              builder: (_, _) {
                // Breathing scale (idle only) + burst scale (on success)
                final burst = sin(_burstCtrl.value * pi) * 0.10;
                final breathe = isClockedIn
                    ? 0.0
                    : _breatheCtrl.value * 0.025;
                final scale = 1.0 + burst + breathe;

                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: _kRingSize,
                    height: _kRingSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Long-press ring (outermost)
                        CustomPaint(
                          size: const Size(_kRingSize, _kRingSize),
                          painter: _LongPressRingPainter(
                            progress: _ringCtrl.value,
                            color: ringColor,
                          ),
                        ),

                        // Analog clock face
                        CustomPaint(
                          size: const Size(_kClockSize, _kClockSize),
                          painter: _AnalogClockPainter(
                            now: _now,
                            isClockedIn: isClockedIn,
                          ),
                        ),

                        // Loading spinner overlay
                        if (_actionInProgress)
                          SizedBox(
                            width: _kClockSize,
                            height: _kClockSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // ── Elapsed time (when clocked in) ──────────────────────────────
          if (isClockedIn)
            _ActiveClockInfo(
              key: const ValueKey('elapsed'),
              elapsed: _elapsed,
              clockInTime: _ongoingSession!.clockIn,
            ),

          const SizedBox(height: 5),

          // ── Instruction label ──────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              isClockedIn ? 'לחיצה ארוכה לסיום משמרת' : 'לחיצה ארוכה להתחיל משמרת',
              key: ValueKey(isClockedIn),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.60),
                letterSpacing: 0.2,
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  Active clock info widget (when clocked in) — elapsed + clock-in time
// ═════════════════════════════════════════════════════════════════════════════

class _ActiveClockInfo extends StatelessWidget {
  final Duration elapsed;
  final DateTime clockInTime;

  const _ActiveClockInfo({
    super.key,
    required this.elapsed,
    required this.clockInTime,
  });

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final elapsedStr =
        '${two(elapsed.inHours)}:${two(elapsed.inMinutes.remainder(60))}:${two(elapsed.inSeconds.remainder(60))}';
    final sinceStr = 'מאז ${two(clockInTime.hour)}:${two(clockInTime.minute)}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          elapsedStr,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _kSecondHandActive,
            letterSpacing: 3.0,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          sinceStr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.55),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
//  Analog clock CustomPainter
// ═════════════════════════════════════════════════════════════════════════════

class _AnalogClockPainter extends CustomPainter {
  final DateTime now;
  final bool isClockedIn;

  const _AnalogClockPainter({required this.now, required this.isClockedIn});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // ── Clock face (frosted glass) ───────────────────────────────────────
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.13)
          ..style = PaintingStyle.fill);

    // Inner glow ring for active state
    if (isClockedIn) {
      canvas.drawCircle(
          c,
          r - 1,
          Paint()
            ..color = _kSecondHandActive.withOpacity(0.18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }

    // Face border
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    // ── Tick marks (60 positions) ────────────────────────────────────────
    for (int i = 0; i < 60; i++) {
      final angle = i * pi / 30 - pi / 2;
      final isHourMark = i % 5 == 0;
      final tickLen = isHourMark ? 7.0 : 3.5;
      final tickW = isHourMark ? 2.2 : 1.0;
      final opacity = isHourMark ? 0.90 : 0.35;

      _drawLine(
        canvas,
        Offset(c.dx + (r - 3) * cos(angle), c.dy + (r - 3) * sin(angle)),
        Offset(c.dx + (r - 3 - tickLen) * cos(angle),
            c.dy + (r - 3 - tickLen) * sin(angle)),
        Colors.white.withOpacity(opacity),
        tickW,
      );
    }

    // ── Hour hand ────────────────────────────────────────────────────────
    final hAngle =
        (now.hour % 12 + now.minute / 60) * pi / 6 - pi / 2;
    _drawHand(canvas, c, hAngle, r * 0.44, 3.2, Colors.white);

    // ── Minute hand ──────────────────────────────────────────────────────
    final mAngle = (now.minute + now.second / 60) * pi / 30 - pi / 2;
    _drawHand(canvas, c, mAngle, r * 0.63, 2.0, Colors.white);

    // ── Second hand + tail ───────────────────────────────────────────────
    final sAngle = now.second * pi / 30 - pi / 2;
    final secColor =
        isClockedIn ? _kSecondHandActive : _kSecondHandIdle;
    _drawHand(canvas, c, sAngle, r * 0.72, 1.2, secColor); // body
    _drawHand(canvas, c, sAngle + pi, r * 0.18, 1.2, secColor); // tail

    // ── Center dots ──────────────────────────────────────────────────────
    canvas.drawCircle(
        c, 5.0, Paint()..color = Colors.white); // white cap
    canvas.drawCircle(
        c, 2.8, Paint()..color = secColor); // colored center
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Color color) {
    _drawLine(
      canvas,
      center,
      Offset(center.dx + length * cos(angle), center.dy + length * sin(angle)),
      color,
      width,
    );
  }

  void _drawLine(Canvas canvas, Offset a, Offset b, Color color, double width) {
    canvas.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_AnalogClockPainter old) =>
      old.now.second != now.second ||
      old.now.minute != now.minute ||
      old.isClockedIn != isClockedIn;
}

// ═════════════════════════════════════════════════════════════════════════════
//  Long-press ring CustomPainter
// ═════════════════════════════════════════════════════════════════════════════

class _LongPressRingPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0
  final Color color;

  const _LongPressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 5;

    // Track (subtle ghost ring always visible as hint)
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = Colors.white.withOpacity(0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);

    if (progress <= 0) return;

    // Glow layer (blurred, slightly larger)
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Crisp arc
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Leading dot (bright tip of the arc)
    if (progress > 0.01) {
      final tipAngle = -pi / 2 + 2 * pi * progress;
      final tip = Offset(c.dx + r * cos(tipAngle), c.dy + r * sin(tipAngle));
      canvas.drawCircle(tip, 4, Paint()..color = Colors.white);
      canvas.drawCircle(
          tip,
          6,
          Paint()
            ..color = color.withOpacity(0.50)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
  }

  @override
  bool shouldRepaint(_LongPressRingPainter old) =>
      old.progress != progress || old.color != color;
}
