import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/widgets/worker_shift_card.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final ShiftService _shiftService = ShiftService();

  // ✅ Ensure the week starts from Sunday
  DateTime _currentWeekStart =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AppAuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const UserHeader(),
      body: Column(
        children: [
          _buildWeekNavigation(),
          _buildDayTabs(),
          Expanded(child: _buildShiftList(currentUser)),
        ],
      ),
    );
  }

  // 🟢 Week Navigation
  Widget _buildWeekNavigation() {
    final String weekRange =
        "${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd').format(_currentWeekStart.add(const Duration(days: 6)))}";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: AppTheme.navigationBoxDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: AppColors.primary,
            iconSize: 28,
            onPressed: () {
              setState(() {
                _currentWeekStart =
                    _currentWeekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Text(weekRange, style: AppTheme.sectionTitle),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            color: AppColors.primary,
            iconSize: 28,
            onPressed: () {
              setState(() {
                _currentWeekStart =
                    _currentWeekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
    );
  }

  // 🟢 Day Tabs (Sunday - Saturday)
  Widget _buildDayTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (index) {
          final DateTime day = _currentWeekStart.add(Duration(days: index));
          final bool isSelected =
              _selectedDay.day == day.day && _selectedDay.month == day.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDay = day;
              });
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Column(
                children: [
                  Text(
                    DateFormat('E').format(day),
                    style: isSelected
                        ? AppTheme.tabTextStyle
                            .copyWith(color: AppColors.onPrimary)
                        : AppTheme.tabTextStyle,
                  ),
                  Text(
                    DateFormat('dd').format(day),
                    style: isSelected
                        ? AppTheme.tabTextStyle
                            .copyWith(color: AppColors.onPrimary)
                        : AppTheme.tabTextStyle,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // 🟢 Build Shift List
  Widget _buildShiftList(User? currentUser) {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
              child: Text('אין משמרות זמינות כרגע', style: AppTheme.bodyText));
        }

        // 🟢 Filter shifts for the selected day
        final filteredShifts = snapshot.data!.where((shift) {
          return shift.date == DateFormat('dd/MM/yyyy').format(_selectedDay);
        }).toList();

        if (filteredShifts.isEmpty) {
          return const Center(
              child: Text('אין משמרות ליום זה', style: AppTheme.bodyText));
        }

        if (currentUser == null) {
          return const Center(
              child: Text('שגיאה בזיהוי משתמש', style: AppTheme.bodyText));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
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
}
