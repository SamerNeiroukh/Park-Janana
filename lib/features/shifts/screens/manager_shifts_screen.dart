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
      _currentWeekStart.add(const Duration(days: 6)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
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
  // DAY SELECTOR
  // ═══════════════════════════════════════════════════════════

  Widget _buildDaySelector() {
    return Container(
      height: 90,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        reverse: true,
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = _currentWeekStart.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(day, _selectedDay);
          final isToday = DateUtils.isSameDay(day, DateTime.now());

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
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHIFT LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildShiftList() {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        final shifts = snapshot.data!.where((shift) {
          final shiftDate = DateFormat('dd/MM/yyyy').parse(shift.date);
          return DateUtils.isSameDay(shiftDate, _selectedDay);
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
    final isFull = shift.assignedWorkers.length >= shift.maxWorkers;
    final hasRequests = shift.requestedWorkers.isNotEmpty;
    final progress = shift.maxWorkers == 0
        ? 0.0
        : shift.assignedWorkers.length / shift.maxWorkers;

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
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top color strip
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Arrow icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      // Department info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                shift.department,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${shift.startTime} - ${shift.endTime}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  Row(
                    children: [
                      // Status badges
                      if (isFull)
                        _buildStatusBadge('מלא', AppColors.success, Icons.check)
                      else if (hasRequests)
                        _buildStatusBadge(
                          '${shift.requestedWorkers.length} בקשות',
                          AppColors.warningOrange,
                          Icons.pending_actions,
                        ),
                      const Spacer(),
                      // Worker count
                      Text(
                        '${shift.assignedWorkers.length}/${shift.maxWorkers}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isFull ? AppColors.success : color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.people, size: 16, color: Colors.grey.shade500),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Progress bar visual
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(
                        isFull ? AppColors.success : color,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 14, color: color),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy_rounded,
                size: 56,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'אין משמרות ליום זה',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'לחץ על + ליצירת משמרת חדשה',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CREATE SHIFT BUTTON
  // ═══════════════════════════════════════════════════════════

  Widget _buildCreateShiftButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'משמרת חדשה',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
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
      ),
    );
  }
}
