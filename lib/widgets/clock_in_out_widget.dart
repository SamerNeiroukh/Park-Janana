import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:shimmer/shimmer.dart';

import '../models/attendance_model.dart';
import '../services/clock_service.dart';

class ClockInOutWidget extends StatefulWidget {
  const ClockInOutWidget({super.key});

  @override
  State<ClockInOutWidget> createState() => _ClockInOutWidgetState();
}

class _ClockInOutWidgetState extends State<ClockInOutWidget>
    with SingleTickerProviderStateMixin {
  final ClockService _clockService = ClockService();
  AttendanceRecord? _ongoingSession;
  bool _loading = true;
  final GlobalKey<SlideActionState> _key = GlobalKey();
  Timer? _timer;
  DateTime _now = DateTime.now();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _fetchSession();
    _startLiveClock();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startLiveClock() {
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
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
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';

    if (_ongoingSession == null) {
      await _clockService.clockIn(userName);
    } else {
      await _clockService.clockOut();
    }

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
    final clockInTime = isClockedIn
        ? DateFormat.Hm().format(_ongoingSession!.clockIn)
        : '';
    final nowTime = DateFormat.Hm().format(_now);

    final label = isClockedIn ? 'החלק כדי לצאת' : 'החלק כדי להתחיל';
    final subLabel = isClockedIn
        ? '🕒 נכנסת ב־$clockInTime • עכשיו $nowTime'
        : 'אתה כרגע לא מחובר';

    final gradientColors = isClockedIn
        ? [const Color(0xFFFF9966), const Color(0xFFFF5E62)]
        : [const Color(0xFF43cea2), const Color(0xFF185a9d)];

    final icon = isClockedIn ? Icons.task_alt : Icons.access_time;
    final iconColor = isClockedIn ? Colors.deepOrange : Colors.teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0, left: 16, right: 16),
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withOpacity(0.35),
                  blurRadius: 12 + (value * 8),
                  spreadRadius: 1 + (value * 2),
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    subLabel,
                    key: ValueKey(subLabel),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: iconColor.withOpacity(_pulseController.value * 0.3),
                            blurRadius: 20 + (_pulseController.value * 10),
                          ),
                        ],
                      ),
                      child: child,
                    );
                  },
                  child: SlideAction(
                    key: _key,
                    height: 64,
                    borderRadius: 16,
                    elevation: 0,
                    outerColor: Colors.transparent,
                    innerColor: Colors.white,
                    sliderButtonIcon: Icon(
                      icon,
                      size: 30,
                      color: iconColor,
                    ),
                    text: '',
                    onSubmit: () async {
                      await _handleAction();
                    },
                    child: Shimmer.fromColors(
                      baseColor: iconColor,
                      highlightColor: Colors.white.withOpacity(0.8),
                      direction: ShimmerDirection.ltr,
                      period: const Duration(seconds: 2),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 18,
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
        },
      ),
    );
  }
}
