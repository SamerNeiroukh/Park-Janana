import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/config/departments.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/widgets/shimmer_loading.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/shifts/screens/shift_details_screen.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';

class ManagerWeeklyScheduleScreen extends StatefulWidget {
  const ManagerWeeklyScheduleScreen({super.key});

  @override
  State<ManagerWeeklyScheduleScreen> createState() =>
      _ManagerWeeklyScheduleScreenState();
}

class _ManagerWeeklyScheduleScreenState
    extends State<ManagerWeeklyScheduleScreen> {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();
  final ScrollController _scrollController = ScrollController();

  DateTime _weekStart = DateTimeUtils.startOfWeek(DateTime.now());
  String? _selectedDepartment;
  bool _hasAutoScrolled = false;

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

  /// Groups shifts by day for the full 7-day week, including empty days.
  Map<DateTime, List<ShiftModel>> _groupByDay(List<ShiftModel> shifts) {
    final Map<DateTime, List<ShiftModel>> grouped = {};

    // Initialize all 7 days
    for (int i = 0; i < 7; i++) {
      final day = _weekStart.add(Duration(days: i));
      grouped[DateTime(day.year, day.month, day.day)] = [];
    }

    for (final shift in shifts) {
      final d = shift.parsedDate;
      final key = DateTime(d.year, d.month, d.day);
      grouped.putIfAbsent(key, () => []).add(shift);
    }

    return grouped;
  }

  List<ShiftModel> _filterShifts(List<ShiftModel> shifts) {
    var filtered =
        shifts.where((s) => s.status != 'cancelled').toList();
    if (_selectedDepartment != null) {
      filtered = filtered
          .where((s) => s.department == _selectedDepartment)
          .toList();
    }
    return filtered;
  }

  void _autoScrollToToday(List<DateTime> dates) {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    final todayIndex = dates.indexWhere(
        (d) => d.year == now.year && d.month == now.month && d.day == now.day);

    if (todayIndex > 0) {
      final estimatedOffset = todayIndex * 170.0;
      final maxScroll = _scrollController.position.maxScrollExtent;

      _scrollController.animateTo(
        estimatedOffset.clamp(0, maxScroll),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const UserHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _WeekHeader(
              start: _weekStart,
              onPrev: _prevWeek,
              onNext: _nextWeek,
            ),
            _DepartmentFilter(
              selected: _selectedDepartment,
              onChanged: (dept) {
                setState(() => _selectedDepartment = dept);
              },
            ),
            const SizedBox(height: 4),
            Expanded(
              child: StreamBuilder<List<ShiftModel>>(
                key: ValueKey(_weekStart),
                stream: _shiftService.getShiftsForWeek(_weekStart),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const ShimmerLoading(
                      itemCount: 4,
                      cardHeight: 140,
                      cardBorderRadius: 18,
                      padding: EdgeInsets.fromLTRB(24, 12, 24, 32),
                    );
                  }

                  if (snapshot.hasError) {
                    return _ErrorState(
                      onRetry: () => (context as Element).markNeedsBuild(),
                    );
                  }

                  final filtered = _filterShifts(snapshot.data ?? []);
                  final grouped = _groupByDay(filtered);
                  final dates = grouped.keys.toList()..sort();

                  // Sort shifts within each day by start time
                  for (final date in dates) {
                    grouped[date]!
                        .sort((a, b) => a.startTime.compareTo(b.startTime));
                  }

                  // Collect all unique worker IDs for batch fetch
                  final allWorkerIds = filtered
                      .expand((s) => s.assignedWorkers)
                      .toSet()
                      .toList();

                  return FutureBuilder<List<UserModel>>(
                    future: allWorkerIds.isEmpty
                        ? Future.value([])
                        : _workerService.getUsersByIds(allWorkerIds),
                    builder: (context, workerSnapshot) {
                      final workerMap = <String, UserModel>{};
                      if (workerSnapshot.hasData) {
                        for (final w in workerSnapshot.data!) {
                          workerMap[w.uid] = w;
                        }
                      }

                      // Auto-scroll to today
                      if (!_hasAutoScrolled && workerSnapshot.hasData) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _autoScrollToToday(dates);
                          _hasAutoScrolled = true;
                        });
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          await Future.delayed(
                              const Duration(milliseconds: 500));
                        },
                        color: AppColors.primaryBlue,
                        child: ListView.builder(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                          itemCount: dates.length,
                          itemBuilder: (context, index) {
                            final date = dates[index];
                            return _AnimatedDay(
                              index: index,
                              child: _DaySection(
                                date: date,
                                shifts: grouped[date]!,
                                workerMap: workerMap,
                                workersLoading: !workerSnapshot.hasData,
                                onShiftTap: (shift) =>
                                    _showShiftDetails(shift, date, workerMap),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShiftDetails(
      ShiftModel shift, DateTime date, Map<String, UserModel> workerMap) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ShiftDetailSheet(
        shift: shift,
        date: date,
        workerMap: workerMap,
        shiftService: _shiftService,
        workerService: _workerService,
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
    final end = start.add(const Duration(days: 6));
    final range =
        '${DateFormat('dd.MM').format(start)} – ${DateFormat('dd.MM').format(end)}';

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              tooltip: 'שבוע הבא',
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'סידור עבודה שבועי',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
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
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_right_rounded, size: 28),
              tooltip: 'שבוע קודם',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DEPARTMENT FILTER
// ─────────────────────────────────────────────

class _DepartmentFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _DepartmentFilter({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final departments = ['הכל', ...allDepartments];

    return SizedBox(
      height: 46,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: departments.length,
        itemBuilder: (context, index) {
          final dept = departments[index];
          final isAll = dept == 'הכל';
          final isSelected = isAll ? selected == null : selected == dept;
          final color =
              isAll ? AppColors.primaryBlue : getDepartmentColor(dept);

          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              onTap: () => onChanged(isAll ? null : dept),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? color : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  dept,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DAY SECTION
// ─────────────────────────────────────────────

class _DaySection extends StatelessWidget {
  final DateTime date;
  final List<ShiftModel> shifts;
  final Map<String, UserModel> workerMap;
  final bool workersLoading;
  final void Function(ShiftModel) onShiftTap;

  const _DaySection({
    required this.date,
    required this.shifts,
    required this.workerMap,
    required this.workersLoading,
    required this.onShiftTap,
  });

  static const _dayColors = {
    7: Color(0xFFE91E63), // Sunday
    1: Color(0xFF9C27B0), // Monday
    2: Color(0xFF3F51B5), // Tuesday
    3: Color(0xFF009688), // Wednesday
    4: Color(0xFFFF9800), // Thursday
    5: Color(0xFF4CAF50), // Friday
    6: Color(0xFF607D8B), // Saturday
  };

  Color get _dayColor => _dayColors[date.weekday] ?? AppColors.primaryBlue;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisDay = DateTime(date.year, date.month, date.day);

    final isToday = thisDay == today;
    final isPast = thisDay.isBefore(today);

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
                      DateFormat('EEE', 'he').format(date),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            accentColor.withOpacity(isToday ? 0.15 : 0.1),
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
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'היום',
                            style: TextStyle(
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
                          'עבר',
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
              // Timeline line
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentColor.withOpacity(0.6),
                      accentColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              // Shifts column
              Expanded(
                child: shifts.isEmpty
                    ? const _EmptyDayPlaceholder()
                    : Column(
                        children: shifts
                            .map((s) => _ShiftCard(
                                  shift: s,
                                  workerMap: workerMap,
                                  workersLoading: workersLoading,
                                  isPast: isPast,
                                  dayColor: accentColor,
                                  onTap: () => onShiftTap(s),
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
}

// ─────────────────────────────────────────────
// EMPTY DAY PLACEHOLDER
// ─────────────────────────────────────────────

class _EmptyDayPlaceholder extends StatelessWidget {
  const _EmptyDayPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
        color: Colors.grey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            'אין משמרות',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIFT CARD
// ─────────────────────────────────────────────

class _ShiftCard extends StatefulWidget {
  final ShiftModel shift;
  final Map<String, UserModel> workerMap;
  final bool workersLoading;
  final bool isPast;
  final Color dayColor;
  final VoidCallback onTap;

  const _ShiftCard({
    required this.shift,
    required this.workerMap,
    required this.workersLoading,
    required this.isPast,
    required this.dayColor,
    required this.onTap,
  });

  @override
  State<_ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends State<_ShiftCard> {
  bool _isPressed = false;

  Color get _deptColor => getDepartmentColor(widget.shift.department);

  Color get _countColor {
    final assigned = widget.shift.assignedWorkers.length;
    final max = widget.shift.maxWorkers;
    if (assigned == 0) return Colors.red.shade400;
    if (assigned >= max) return const Color(0xFF43A047);
    return _deptColor;
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final cardColor = widget.isPast ? Colors.grey.shade50 : Colors.white;
    final borderColor = widget.isPast
        ? Colors.grey.shade300
        : (_isPressed
            ? _deptColor.withOpacity(0.3)
            : Colors.grey.shade200);

    // Resolve workers for this shift
    final workers = shift.assignedWorkers
        .where((id) => widget.workerMap.containsKey(id))
        .map((id) => widget.workerMap[id]!)
        .toList();

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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: cardColor,
            border: Border.all(color: borderColor),
            boxShadow: widget.isPast
                ? null
                : [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(_isPressed ? 0.08 : 0.05),
                      blurRadius: _isPressed ? 8 : 12,
                      offset: Offset(0, _isPressed ? 2 : 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Department color bar
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: _deptColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: department + worker count
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _deptColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                getDepartmentIcon(shift.department),
                                size: 14,
                                color: _deptColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shift.department,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _deptColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _countColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded,
                                  size: 14, color: _countColor),
                              const SizedBox(width: 3),
                              Text(
                                '${shift.assignedWorkers.length}/${shift.maxWorkers}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _countColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Time row
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${shift.startTime} – ${shift.endTime}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Worker avatars
                    if (widget.workersLoading)
                      _buildAvatarShimmer()
                    else if (workers.isEmpty)
                      Text(
                        'לא שובצו עובדים',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      )
                    else
                      _WorkerAvatarsRow(workers: workers, maxVisible: 5),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_left_rounded,
                  color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarShimmer() {
    return Row(
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.only(left: 4),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WORKER AVATARS ROW
// ─────────────────────────────────────────────

class _WorkerAvatarsRow extends StatelessWidget {
  final List<UserModel> workers;
  final int maxVisible;

  const _WorkerAvatarsRow({
    required this.workers,
    this.maxVisible = 5,
  });

  @override
  Widget build(BuildContext context) {
    final visibleCount =
        workers.length > maxVisible ? maxVisible : workers.length;
    final overflow = workers.length - visibleCount;
    final totalItems = visibleCount + (overflow > 0 ? 1 : 0);
    final totalWidth = totalItems * 22.0 + 8.0;

    return SizedBox(
      height: 30,
      width: totalWidth,
      child: Stack(
        children: [
          for (int i = 0; i < visibleCount; i++)
            Positioned(
              left: i * 22.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ProfileAvatar(
                  imageUrl: workers[i].profilePicture,
                  radius: 14,
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: visibleCount * 22.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.white, spreadRadius: 2),
                  ],
                ),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '+$overflow',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHIFT DETAIL SHEET
// ─────────────────────────────────────────────

class _ShiftDetailSheet extends StatelessWidget {
  final ShiftModel shift;
  final DateTime date;
  final Map<String, UserModel> workerMap;
  final ShiftService shiftService;
  final WorkerService workerService;

  const _ShiftDetailSheet({
    required this.shift,
    required this.date,
    required this.workerMap,
    required this.shiftService,
    required this.workerService,
  });

  Color get _deptColor => getDepartmentColor(shift.department);

  @override
  Widget build(BuildContext context) {
    final workers = shift.assignedWorkers
        .where((id) => workerMap.containsKey(id))
        .map((id) => workerMap[id]!)
        .toList();

    final assigned = shift.assignedWorkers.length;
    final max = shift.maxWorkers;
    final progress = max > 0 ? (assigned / max).clamp(0.0, 1.0) : 0.0;

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
              color: _deptColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(getDepartmentIcon(shift.department),
                    size: 18, color: _deptColor),
                const SizedBox(width: 6),
                Text(
                  shift.department,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _deptColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Date
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, d בMMMM', 'he').format(date),
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Time
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time_rounded,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${shift.startTime} – ${shift.endTime}',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Worker progress
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'עובדים משובצים',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    Text(
                      '$assigned/$max',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: assigned >= max
                            ? const Color(0xFF43A047)
                            : _deptColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    color: assigned >= max
                        ? const Color(0xFF43A047)
                        : _deptColor,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Divider
          Divider(color: Colors.grey.shade200, height: 1),

          // Worker list
          if (workers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'לא שובצו עובדים למשמרת זו',
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade500),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                itemCount: workers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  return Row(
                    children: [
                      ProfileAvatar(
                        imageUrl: worker.profilePicture,
                        radius: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker.fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              worker.role == 'manager'
                                  ? 'מנהל'
                                  : 'עובד',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Navigate to full details
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ShiftDetailsScreen(
                        shift: shift,
                        shiftService: shiftService,
                        workerService: workerService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _deptColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'צפה בפרטי המשמרת',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
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
// ERROR STATE
// ─────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'שגיאה בטעינת המשמרות',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('נסה שוב'),
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
