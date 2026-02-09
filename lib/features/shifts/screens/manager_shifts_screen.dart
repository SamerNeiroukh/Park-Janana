import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'create_shift_screen.dart';
import 'shift_details_screen.dart';

class ManagerShiftsScreen extends StatefulWidget {
  const ManagerShiftsScreen({super.key});

  @override
  State<ManagerShiftsScreen> createState() => _ManagerShiftsScreenState();
}

class _ManagerShiftsScreenState extends State<ManagerShiftsScreen> {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();

  DateTime _currentWeekStart = DateTimeUtils.startOfWeek(DateTime.now());
  DateTime _selectedDay = DateTime.now();
  bool _isNavigating = false;

  Color _getDepartmentColor(String department) {
    switch (department) {
      case 'פיינטבול':
        return const Color(0xFFE53935);
      case 'פארק חבלים':
        return const Color(0xFF43A047);
      case 'קרטינג':
        return const Color(0xFFFF9800);
      case 'פארק מים':
        return const Color(0xFF1E88E5);
      case 'גמבורי':
        return const Color(0xFF8E24AA);
      default:
        return AppColors.primary;
    }
  }

  IconData _getDepartmentIcon(String department) {
    switch (department) {
      case 'פיינטבול':
        return Icons.sports_esports;
      case 'פארק חבלים':
        return Icons.park;
      case 'קרטינג':
        return Icons.directions_car;
      case 'פארק מים':
        return Icons.pool;
      case 'גמבורי':
        return Icons.child_care;
      default:
        return Icons.work;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        floatingActionButton: _buildCreateShiftButton(),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            _buildWeekHeader(),
            _buildDaySelector(),
            Expanded(child: _buildShiftList()),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WEEK HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildWeekHeader() {
    final startDate = DateTimeUtils.formatDate(_currentWeekStart);
    final endDate = DateTimeUtils.formatDate(
        _currentWeekStart.add(const Duration(days: 6)));

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavButton(
            icon: Icons.chevron_left,
            onTap: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.subtract(const Duration(days: 7));
              _selectedDay = _currentWeekStart;
            }),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'ניהול משמרות',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$startDate - $endDate',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildNavButton(
            icon: Icons.chevron_right,
            onTap: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.add(const Duration(days: 7));
              _selectedDay = _currentWeekStart;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DAY SELECTOR — FIXED RTL ORDER (SAT → SUN)
  // ═══════════════════════════════════════════════════════════

  Widget _buildDaySelector() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          reverse: true, // Shows Sunday on right, Saturday on left
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 7,
          itemBuilder: (context, index) {
            // RTL order: Sunday (index 0) on right → Saturday (index 6) on left
            final DateTime day = _currentWeekStart.add(Duration(days: index));

          final bool isSelected = DateUtils.isSameDay(day, _selectedDay);
          final bool isToday = DateUtils.isSameDay(day, DateTime.now());

          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.8),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isToday && !isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.4)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTimeUtils.getHebrewWeekdayName(day.weekday),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        DateFormat('dd').format(day),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                                  ? AppColors.primary
                                  : Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHIFT LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildShiftList() {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsForWeek(_currentWeekStart),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final shifts = snapshot.data!.where((shift) {
          return shift.date == DateFormat('dd/MM/yyyy').format(_selectedDay);
        }).toList();

        if (shifts.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: shifts.length,
          itemBuilder: (context, index) => _buildShiftCard(shifts[index]),
        );
      },
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    final color = _getDepartmentColor(shift.department);
    final icon = _getDepartmentIcon(shift.department);
    final assignedCount = shift.assignedWorkers.length;
    final maxWorkers = shift.maxWorkers;
    final requestsCount = shift.requestedWorkers.length;
    final isFull = assignedCount >= maxWorkers;
    final isCancelled = shift.status == 'cancelled';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShiftDetailsScreen(
            shift: shift,
            shiftService: _shiftService,
            workerService: _workerService,
          ),
        ),
      ),
      child: Opacity(
        opacity: isCancelled ? 0.65 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isCancelled ? Colors.grey.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: isCancelled
                    ? Colors.grey.withOpacity(0.1)
                    : color.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top color strip
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.red.shade400 : color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Main row
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? Colors.red.shade50
                                : color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCancelled ? Icons.cancel_rounded : icon,
                            color: isCancelled ? Colors.red.shade400 : color,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.department,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isCancelled
                                      ? Colors.grey.shade500
                                      : color,
                                  decoration: isCancelled
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: Colors.red.shade300,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 14, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${shift.startTime} - ${shift.endTime}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      decoration: isCancelled
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Info row
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        if (!isCancelled) ...[
                          // Workers count
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isFull
                                  ? AppColors.success.withOpacity(0.1)
                                  : color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              textDirection: TextDirection.rtl,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: isFull ? AppColors.success : color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$assignedCount/$maxWorkers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isFull ? AppColors.success : color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Pending requests
                          if (requestsCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warningOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                textDirection: TextDirection.rtl,
                                children: [
                                  const Icon(
                                    Icons.pending_actions,
                                    size: 14,
                                    color: AppColors.warningOrange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$requestsCount בקשות',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warningOrange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        const Spacer(),
                        // Status chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: shift.status == 'active'
                                ? AppColors.success.withOpacity(0.1)
                                : shift.status == 'cancelled'
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.rtl,
                            children: [
                              if (isCancelled)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.cancel, size: 14,
                                      color: Colors.red.shade600),
                                ),
                              Text(
                                shift.status == 'active'
                                    ? 'פעיל'
                                    : shift.status == 'cancelled'
                                        ? 'בוטלה'
                                        : shift.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: shift.status == 'active'
                                      ? AppColors.success
                                      : shift.status == 'cancelled'
                                          ? Colors.red.shade600
                                          : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('אין משמרות ליום זה'),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CREATE SHIFT BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _buildCreateShiftButton() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add, color: Colors.white),
      label: const Text(
        'משמרת חדשה',
        style: TextStyle(color: Colors.white),
      ),
      onPressed: _isNavigating
          ? null
          : () async {
              setState(() => _isNavigating = true);
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateShiftScreen(initialDate: _selectedDay),
                ),
              );
              if (mounted) setState(() => _isNavigating = false);
            },
    );
  }
}
