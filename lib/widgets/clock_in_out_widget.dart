import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:shimmer/shimmer.dart';

import '../models/attendance_model.dart';
import '../services/clock_service.dart';
import '../utils/location_utils.dart'; // ✅ NEW

class ClockInOutWidget extends StatefulWidget {
  const ClockInOutWidget({super.key});

  @override
  State<ClockInOutWidget> createState() => _ClockInOutWidgetState();
}

class _ClockInOutWidgetState extends State<ClockInOutWidget>
    with TickerProviderStateMixin {
  final ClockService _clockService = ClockService();
  AttendanceRecord? _ongoingSession;
  bool _loading = true;
  bool _justSubmitted = false;

  final GlobalKey<SlideActionState> _key = GlobalKey();
  Timer? _clockTimer;
  Timer? _elapsedTimer;
  Timer? _quoteTimer;

  DateTime _now = DateTime.now();
  Duration _elapsed = Duration.zero;

  late AnimationController _pulseController;
  late AnimationController _cardPulseController;
  late AnimationController _clockRotateController;

  final List<String> _quotes = [
    "! היום זו הזדמנות חדשה להצטיין",
    "! תן את המיטב שלך בפארק היום",
    "אתה חלק חשוב בצוות שלנו 💪",
    "כל משמרת היא הזדמנות להשפיע ✨",
    "תשמור על חיוך – זה מדבק 😄",
  ];
  int _quoteIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _cardPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      lowerBound: 0.0,
      upperBound: 0.04,
    );

    _clockRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _startQuoteTimer();
    _fetchSession();
    _startLiveClock();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _elapsedTimer?.cancel();
    _quoteTimer?.cancel();
    _pulseController.dispose();
    _cardPulseController.dispose();
    _clockRotateController.dispose();
    super.dispose();
  }

  void _startLiveClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    if (_ongoingSession != null) {
      _elapsed = DateTime.now().difference(_ongoingSession!.clockIn);
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {
            _elapsed = DateTime.now().difference(_ongoingSession!.clockIn);
          });
        }
      });
    }
  }

  void _startQuoteTimer() {
    _quoteTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % _quotes.length;
      });
    });
  }

  Future<void> _fetchSession() async {
    try {
      final session = await _clockService.getOngoingClockIn();
      if (!mounted) return;
      setState(() {
        _ongoingSession = session;
        _loading = false;
        _now = DateTime.now();
      });
      if (_ongoingSession != null) {
        _startElapsedTimer();
      }
    } catch (e) {
      debugPrint('Error fetching session: $e');
      if (mounted) {
        setState(() {
          _ongoingSession = null;
          _loading = false;
        });
      }
    }
  }

  Future<void> _handleAction() async {
    final userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';

    final insidePark = await LocationUtils.isInsidePark();
    final isClockingIn = _ongoingSession == null;

    if (!insidePark) {
      final confirm = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Location Warning',
        barrierColor: Colors.black54.withOpacity(0.6), // dimmed background
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Location Icon with glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEE7752), Color(0xFFD8363A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Icon(
                        Icons.location_off_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Bold Title
                    const Text(
                      'אינך נמצא בגבולות הפארק',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Normal text description
                    Text(
                      'אתה מנסה ${isClockingIn ? 'להתחבר' : 'להתנתק'} מחוץ לאזור המותר. האם ברצונך להמשיך בכל זאת',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button ("לא")
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            minimumSize: const Size(100, 48),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text(
                            'לא',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),

                        // Confirm button ("כן")
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(100, 48),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD8363A), Color(0xFFEE7752)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              child: const Text(
                                'כן',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
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
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curvedValue = Curves.easeInOut.transform(animation.value);
          return Opacity(
            opacity: curvedValue,
            child: Transform.scale(
              scale: curvedValue,
              child: child,
            ),
          );
        },
      );

      if (confirm != true) {
        _key.currentState?.reset();
        return;
      }
    }

    if (_ongoingSession == null) {
      await _clockService.clockIn(userName);
    } else {
      await _clockService.clockOut();
    }

    setState(() => _justSubmitted = true);
    _cardPulseController.forward(from: 0).then((_) {
      _cardPulseController.reverse().then((_) {
        setState(() => _justSubmitted = false);
      });
    });

    await _fetchSession();
    _key.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 30),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final isClockedIn = _ongoingSession != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 16, right: 16),
      child: AnimatedBuilder(
        animation: _cardPulseController,
        builder: (context, child) {
          final scale = 1 - _cardPulseController.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isClockedIn
                    ? [Color(0xFFFF6A6A), Color(0xFFFFB88C)]
                    : [Color.fromARGB(255, 79, 88, 254), Color(0xFF00f2fe)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildContent(isClockedIn),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isClockedIn) {
    final iconColor = isClockedIn ? Colors.deepOrange : Colors.teal;
    final icon = isClockedIn ? Icons.task_alt : Icons.access_time;
    final label = isClockedIn ? 'החלק כדי לצאת' : 'החלק כדי להתחיל';

    final clockInTime =
        isClockedIn ? DateFormat.Hm().format(_ongoingSession!.clockIn) : '';
    final nowTime = DateFormat.Hm().format(_now);

    final subLabel = isClockedIn
        ? ' נכנסת ב־$clockInTime  •  עכשיו $nowTime'
        : 'אתה כרגע לא מחובר';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              if (isClockedIn)
                _buildLiveCounter()
              else
                _buildMotivationalQuote(),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Text(
                  subLabel,
                  key: ValueKey(subLabel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color:
                          iconColor.withOpacity(_pulseController.value * 0.3),
                      blurRadius: 18 + (_pulseController.value * 8),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: SlideAction(
              key: _key,
              height: 56,
              borderRadius: 16,
              elevation: 0,
              outerColor: Colors.transparent,
              innerColor: Colors.white,
              sliderButtonIcon: RotationTransition(
                turns: _ongoingSession == null
                    ? _clockRotateController
                    : const AlwaysStoppedAnimation(0),
                child: Icon(icon, size: 26, color: iconColor),
              ),
              text: '',
              onSubmit: () async => await _handleAction(),
              child: Shimmer.fromColors(
                baseColor: iconColor,
                highlightColor: Colors.white.withOpacity(0.8),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCounter() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final h = twoDigits(_elapsed.inHours);
    final m = twoDigits(_elapsed.inMinutes.remainder(60));
    final s = twoDigits(_elapsed.inSeconds.remainder(60));

    return Text(
      '$h:$m:$s',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildMotivationalQuote() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Text(
        _quotes[_quoteIndex],
        key: ValueKey(_quoteIndex),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
