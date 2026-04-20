import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/features/shifts/screens/shifts_screen.dart';

class MyWeeklyScheduleScreen extends StatefulWidget {
  /// When provided (e.g. tapped from a notification), the screen jumps to
  /// the week containing this shift and auto-opens its details bottom sheet.
  final ShiftModel? initialShift;

  const MyWeeklyScheduleScreen({super.key, this.initialShift});

  @override
  State<MyWeeklyScheduleScreen> createState() => _MyWeeklyScheduleScreenState();
}

class _MyWeeklyScheduleScreenState extends State<MyWeeklyScheduleScreen> {
  final ShiftService _shiftService = ShiftService();
  final ScrollController _scrollController = ScrollController();

  late DateTime _weekStart;
  bool _hasAutoScrolled = false;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialShift;
    if (initial != null) {
      // Jump to the week that contains the assigned shift.
      _weekStart = DateTimeUtils.startOfWeek(initial.parsedDate);
      // After the screen finishes its first render, pop open the shift sheet.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final d = initial.parsedDate;
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => _ShiftDetailsSheet(
            shift: initial,
            date: DateTime(d.year, d.month, d.day),
          ),
        );
      });
    } else {
      _weekStart = DateTimeUtils.startOfWeek(DateTime.now());
    }
  }

  void _prevWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _hasAutoScrolled = false;
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _hasAutoScrolled = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const UserHeader(),
      body: Column(
        children: [
          _WeekHeader(
            start: _weekStart,
            onPrev: _prevWeek,
            onNext: _nextWeek,
          ),
          Expanded(
            child: user == null
                ? _ErrorState(message: _l10n.loginToViewShifts)
                : _Timeline(
                    userId: user.uid,
                    weekStart: _weekStart,
                    shiftService: _shiftService,
                    controller: _scrollController,
                    hasAutoScrolled: _hasAutoScrolled,
                    onAutoScrollComplete: () {
                      _hasAutoScrolled = true;
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WEEK HEADER
// ─────────────────────────────────────────────

class _WeekHeader extends StatelessWidget {
  final DateTime start;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _WeekHeader({
    required this.start,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final end = start.add(const Duration(days: 6));
    final range =
        '${DateFormat('dd.MM').format(end)} – ${DateFormat('dd.MM').format(start)}';

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: isRtl ? onNext : onPrev,
            icon: const Icon(PhosphorIconsRegular.caretLeft),
            tooltip: isRtl ? l10n.nextWeekTooltip : l10n.prevWeekTooltip,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  l10n.myShiftsTitle,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  range,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: isRtl ? onPrev : onNext,
            icon: const Icon(PhosphorIconsRegular.caretRight),
            tooltip: isRtl ? l10n.prevWeekTooltip : l10n.nextWeekTooltip,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// TIMELINE
// ─────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final String userId;
  final DateTime weekStart;
  final ShiftService shiftService;
  final ScrollController controller;
  final bool hasAutoScrolled;
  final VoidCallback onAutoScrollComplete;

  const _Timeline({
    required this.userId,
    required this.weekStart,
    required this.shiftService,
    required this.controller,
    required this.hasAutoScrolled,
    required this.onAutoScrollComplete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ShiftModel>>(
      stream: shiftService.getShiftsForWeek(weekStart),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _LoadingState();
        }

        // Error state
        if (snapshot.hasError) {
          final l10n = AppLocalizations.of(context);
          return _ErrorState(
            message: l10n.loadShiftsError,
            onRetry: () {
              // Trigger rebuild by accessing the stream again
              (context as Element).markNeedsBuild();
            },
          );
        }

        final shifts = (snapshot.data ?? [])
            .where((s) => s.isUserAssigned(userId) && s.status != 'cancelled')
            .toList();

        // Group into all 7 days of the week (even days with no shifts).
        final grouped = _groupShiftsByDate(shifts);
        final dates = grouped.keys.toList()..sort();

        // Sort shifts within each day
        for (final date in dates) {
          grouped[date]!.sort((a, b) => a.startTime.compareTo(b.startTime));
        }

        // Auto-scroll to today (only once)
        if (!hasAutoScrolled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _autoScrollToToday(dates);
            onAutoScrollComplete();
          });
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Stream will auto-refresh, just wait a bit for UX
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primaryBlue,
          child: ListView.builder(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              return _AnimatedDay(
                index: index,
                child: _DayTimeline(
                  date: date,
                  shifts: grouped[date]!,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Map<DateTime, List<ShiftModel>> _groupShiftsByDate(List<ShiftModel> shifts) {
    final Map<DateTime, List<ShiftModel>> grouped = {};
    // Always initialise all 7 days of the current week so the user sees
    // the full week structure even on days without shifts.
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      grouped[DateTime(day.year, day.month, day.day)] = [];
    }
    for (final shift in shifts) {
      final d = shift.parsedDate;
      final key = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(key, () => []).add(shift);
    }
    return grouped;
  }

  void _autoScrollToToday(List<DateTime> dates) {
    if (!controller.hasClients) return;

    final now = DateTime.now();
    final todayIndex = dates.indexWhere(
        (d) => d.year == now.year && d.month == now.month && d.day == now.day);

    if (todayIndex > 0) {
      // Estimate position - scroll to show today near top
      final estimatedOffset = todayIndex * 150.0;
      final maxScroll = controller.position.maxScrollExtent;

      controller.animateTo(
        estimatedOffset.clamp(0, maxScroll),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }
}

// ─────────────────────────────────────────────
// DAY + SHIFTS
// ─────────────────────────────────────────────

class _DayTimeline extends StatelessWidget {
  final DateTime date;
  final List<ShiftModel> shifts;

  const _DayTimeline({
    required this.date,
    required this.shifts,
  });

  // Color for each day of week (Sunday = 7 in Dart's weekday)
  static const _dayColors = {
    7: Color(0xFFE91E63), // Sunday - Pink
    1: Color(0xFF9C27B0), // Monday - Purple
    2: Color(0xFF3F51B5), // Tuesday - Indigo
    3: Color(0xFF009688), // Wednesday - Teal
    4: Color(0xFFFF9800), // Thursday - Orange
    5: Color(0xFF4CAF50), // Friday - Green
    6: Color(0xFF607D8B), // Saturday - Blue Grey
  };

  Color get _dayColor => _dayColors[date.weekday] ?? AppColors.primaryBlue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(date.year, date.month, date.day);

    final isToday = thisDay == today;
    final isPast = thisDay.isBefore(today);

    // Determine colors based on day state
    final Color accentColor;
    final Color textColor;
    final double opacity;

    if (isToday) {
      accentColor = AppColors.primaryBlue;
      textColor = AppColors.primaryBlue;
      opacity = 1.0;
    } else if (isPast) {
      accentColor = Colors.grey.shade400;
      textColor = Colors.grey.shade500;
      opacity = 0.6;
    } else {
      accentColor = _dayColor;
      textColor = _dayColor;
      opacity = 1.0;
    }

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day label column
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE', Localizations.localeOf(context).languageCode).format(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isToday ? 0.15 : 0.1),
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: accentColor, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    if (isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.todayLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (isPast && !isToday)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.pastLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Timeline line with gradient
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withValues(alpha: 0.6),
                      accentColor.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // Shifts column
              Expanded(
                child: shifts.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          l10n.noShiftsDay,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : Column(
                        children: shifts
                            .map((s) => _ShiftPill(
                                  shift: s,
                                  isPast: isPast,
                                  dayColor: accentColor,
                                  onTap: () => _showShiftDetails(context, s),
                                ))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showShiftDetails(BuildContext context, ShiftModel shift) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShiftDetailsSheet(shift: shift, date: date),
    );
  }
}

// ─────────────────────────────────────────────
// SHIFT PILL
// ─────────────────────────────────────────────

class _ShiftPill extends StatefulWidget {
  final ShiftModel shift;
  final VoidCallback onTap;
  final bool isPast;
  final Color dayColor;

  const _ShiftPill({
    required this.shift,
    required this.onTap,
    this.isPast = false,
    this.dayColor = AppColors.primaryBlue,
  });

  @override
  State<_ShiftPill> createState() => _ShiftPillState();
}

class _ShiftPillState extends State<_ShiftPill> {
  bool _isPressed = false;

  Color get _departmentColor {
    switch (widget.shift.department) {
      case 'פיינטבול':
        return Colors.redAccent;
      case 'פארק חבלים':
        return Colors.green;
      case 'קארטינג':
        return Colors.orange;
      case 'פארק מים':
        return Colors.blueAccent;
      default:
        return widget.dayColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = widget.isPast ? Colors.grey.shade50 : Colors.white;
    final borderColor = widget.isPast
        ? Colors.grey.shade300
        : (_isPressed
            ? _departmentColor.withValues(alpha: 0.3)
            : Colors.grey.shade200);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cardColor,
            border: Border.all(color: borderColor),
            boxShadow: widget.isPast
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: _isPressed ? 0.08 : 0.05),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Department color indicator
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: _departmentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              // Time
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.shift.startTime,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.shift.endTime,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Department
              Expanded(
                child: Text(
                  widget.shift.department,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Arrow indicator
              Icon(
                PhosphorIconsRegular.caretRight,
                color: Colors.grey.shade400,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIFT DETAILS SHEET
// ─────────────────────────────────────────────

class _ShiftDetailsSheet extends StatelessWidget {
  final ShiftModel shift;
  final DateTime date;

  const _ShiftDetailsSheet({
    required this.shift,
    required this.date,
  });

  Color get _departmentColor {
    switch (shift.department) {
      case 'פיינטבול':
        return Colors.redAccent;
      case 'פארק חבלים':
        return Colors.green;
      case 'קארטינג':
        return Colors.orange;
      case 'פארק מים':
        return Colors.blueAccent;
      default:
        return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Department badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _departmentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              shift.department,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _departmentColor,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.calendarBlank,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                DateFormat.MMMMEEEEd(Localizations.localeOf(context).languageCode).format(date),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Time
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(PhosphorIconsRegular.clock,
                  size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${shift.startTime} – ${shift.endTime}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // View full details button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftsScreen(initialDate: date),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _departmentColor,
                        _departmentColor.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _departmentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.arrowRight,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).viewShiftDetailsButton,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ANIMATED DAY
// ─────────────────────────────────────────────

class _AnimatedDay extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedDay({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 50)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 16),
            child: child,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryBlue,
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).loadingShifts,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.warningCircle,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 18),
                label: Text(AppLocalizations.of(context).retryButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
