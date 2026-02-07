import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/widgets/worker_shift_card.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final ShiftService _shiftService = ShiftService();

  DateTime _currentWeekStart =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentUser = authProvider.user;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            _buildWeekHeader(),
            _buildDaySelector(),
            Expanded(child: _buildShiftList(currentUser)),
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
                  'משמרות זמינות',
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
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          reverse: true, // Shows Sunday on right, Saturday on left
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // SHIFT LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildShiftList(User? currentUser) {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'אין משמרות זמינות כרגע',
            'בקרוב יתווספו משמרות חדשות',
          );
        }

        final filteredShifts = snapshot.data!.where((shift) {
          return shift.date == DateFormat('dd/MM/yyyy').format(_selectedDay);
        }).toList();

        if (filteredShifts.isEmpty) {
          return _buildEmptyState(
            'אין משמרות ליום זה',
            'בחר יום אחר או המתן למשמרות חדשות',
          );
        }

        if (currentUser == null) {
          return _buildEmptyState(
            'שגיאה בזיהוי משתמש',
            'נסה להתחבר מחדש',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: filteredShifts.length,
          itemBuilder: (context, index) {
            return WorkerShiftCard(
              shift: filteredShifts[index],
              shiftService: _shiftService,
              currentUser: currentUser,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
