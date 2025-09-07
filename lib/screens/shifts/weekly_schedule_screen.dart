import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../services/shift_service.dart';
import '../../widgets/user_header.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../utils/datetime_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final ShiftService _shiftService = ShiftService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  DateTime _currentWeekStart = DateTimeUtils.startOfWeek(DateTime.now());
  List<ShiftModel> _weekShifts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWeekShifts();
  }

  Future<void> _loadWeekShifts() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final shifts = await _shiftService.getShiftsByWeek(_currentWeekStart);
      if (mounted) {
        setState(() {
          _weekShifts = shifts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת המשמרות: $e')),
        );
      }
    }
  }

  void _navigateWeek(int direction) {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * direction));
    });
    _loadWeekShifts();
  }

  List<ShiftModel> _getShiftsForDay(DateTime day) {
    final dayString = DateFormat('dd/MM/yyyy').format(day);
    return _weekShifts.where((shift) => shift.date == dayString).toList();
  }

  void _onDayTap(DateTime day) {
    final dayShifts = _getShiftsForDay(day);
    if (dayShifts.isEmpty) return;

    // Show day details in a bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDayDetailsSheet(day, dayShifts),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserHeader(),
      body: Column(
        children: [
          _buildWeekNavigation(),
          const SizedBox(height: 16),
          _buildWeekHeaders(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    final weekStart = _currentWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 6));
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: AppTheme.navigationBoxDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            color: AppColors.primary,
            iconSize: 24,
            onPressed: () => _navigateWeek(-1),
          ),
          Text(
            "${DateFormat('dd/MM').format(weekStart)} - ${DateFormat('dd/MM').format(weekEnd)}",
            style: AppTheme.sectionTitle.copyWith(fontSize: 18),
            textDirection: TextDirection.rtl,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            color: AppColors.primary,
            iconSize: 24,
            onPressed: () => _navigateWeek(1),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHeaders() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(7, (index) {
          // Hebrew calendar starts with Sunday
          final dayIndex = (6 - index) % 7; // RTL: Sunday=6, Monday=5, ..., Saturday=0
          final weekday = dayIndex == 6 ? 7 : dayIndex + 1; // Convert to DateTime weekday
          final dayName = DateTimeUtils.getHebrewWeekdayName(weekday);
          
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dayName,
                textAlign: TextAlign.center,
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(7, (index) {
          // RTL layout: index 0 is Saturday, index 6 is Sunday
          final dayOffset = 6 - index;
          final day = _currentWeekStart.add(Duration(days: dayOffset));
          final dayShifts = _getShiftsForDay(day);
          
          return Expanded(
            child: GestureDetector(
              onTap: () => _onDayTap(day),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Day number header
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isToday(day) ? AppColors.primary : AppColors.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        '${day.day}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isToday(day) ? Colors.white : AppColors.textPrimary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Shifts list
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: dayShifts.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                children: dayShifts.take(3).map((shift) => 
                                  _buildShiftChip(shift)
                                ).toList(),
                              ),
                      ),
                    ),
                    // More indicator
                    if (dayShifts.length > 3)
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: Text(
                          '+${dayShifts.length - 3} עוד',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildShiftChip(ShiftModel shift) {
    final isUserAssigned = shift.isUserAssigned(_currentUser?.uid ?? '');
    final isUserRequested = shift.requestedWorkers.contains(_currentUser?.uid ?? '');
    
    Color chipColor;
    Color textColor = Colors.white;
    
    if (isUserAssigned) {
      chipColor = AppColors.success;
    } else if (isUserRequested) {
      chipColor = AppColors.secondary;
      textColor = Colors.black;
    } else {
      chipColor = AppColors.border;
      textColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${shift.startTime}-${shift.endTime}',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 9,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  bool _isToday(DateTime day) {
    final today = DateTime.now();
    return day.year == today.year && 
           day.month == today.month && 
           day.day == today.day;
  }

  Widget _buildDayDetailsSheet(DateTime day, List<ShiftModel> shifts) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              DateTimeUtils.formatDateWithDay(DateFormat('dd/MM/yyyy').format(day)),
              style: AppTheme.screenTitle,
              textDirection: TextDirection.rtl,
            ),
          ),
          const Divider(height: 1),
          // Shifts list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                return _buildDetailedShiftCard(shift);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedShiftCard(ShiftModel shift) {
    final isUserAssigned = shift.isUserAssigned(_currentUser?.uid ?? '');
    final isUserRequested = shift.requestedWorkers.contains(_currentUser?.uid ?? '');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${shift.startTime} - ${shift.endTime}',
                style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUserAssigned 
                      ? AppColors.success.withOpacity(0.1)
                      : isUserRequested
                          ? AppColors.secondary.withOpacity(0.1)
                          : AppColors.border.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUserAssigned 
                        ? AppColors.success
                        : isUserRequested
                            ? AppColors.secondary
                            : AppColors.border,
                  ),
                ),
                child: Text(
                  isUserAssigned 
                      ? 'מאושר'
                      : isUserRequested
                          ? 'נשלח'
                          : 'זמין',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUserAssigned 
                        ? AppColors.success
                        : isUserRequested
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.business,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                shift.department,
                style: AppTheme.bodyText.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.group,
                color: AppColors.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${shift.assignedWorkers.length}/${shift.maxWorkers} עובדים',
                style: AppTheme.bodyText.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}