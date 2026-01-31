import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'create_shift_screen.dart';
import 'package:park_janana/features/shifts/widgets/shift_card.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_colors.dart';

class ManagerShiftsScreen extends StatefulWidget {
  const ManagerShiftsScreen({super.key});

  @override
  State<ManagerShiftsScreen> createState() => _ManagerShiftsScreenState();
}

class _ManagerShiftsScreenState extends State<ManagerShiftsScreen>
    with SingleTickerProviderStateMixin {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();
  late TabController _tabController;
  DateTime _currentWeekStart = DateTimeUtils.startOfWeek(DateTime.now());
  late DateTime _selectedDay;

  bool _isNavigating = false; // ✅ Add tap-spam prevention flag

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    final int initialTabIndex = _selectedDay.weekday % 7;
    _tabController =
        TabController(length: 7, vsync: this, initialIndex: initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const UserHeader(),
          _buildWeekNavigation(),
          _buildTabBar(),
          Expanded(
            child: SingleChildScrollView(
              child: Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(7, (index) {
                        final DateTime day =
                            _currentWeekStart.add(Duration(days: index));
                        return _buildShiftList(day);
                      }),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildCreateShiftButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: AppTheme.navigationBoxDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.primary, size: 28),
            onPressed: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.subtract(const Duration(days: 7));
            }),
          ),
          Expanded(
            child: Text(
              "${DateTimeUtils.formatDate(_currentWeekStart)} - ${DateTimeUtils.formatDate(_currentWeekStart.add(const Duration(days: 6)))}",
              style: AppTheme.screenTitle,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward,
                color: AppColors.primary, size: 28),
            onPressed: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.add(const Duration(days: 7));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 70,
      color: AppColors.surface,
      child: DefaultTabController(
        length: 7,
        child: TabBar(
          controller: _tabController,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          isScrollable: true,
          tabs: List.generate(7, (index) {
            final DateTime day = _currentWeekStart.add(Duration(days: index));
            return SizedBox(
              width: MediaQuery.of(context).size.width / 7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTimeUtils.getHebrewWeekdayName(day.weekday),
                    style: AppTheme.tabTextStyle,
                  ),
                  Text(
                    DateFormat('dd').format(day),
                    style: AppTheme.bodyText
                        .copyWith(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildShiftList(DateTime selectedDay) {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyShiftsMessage();
        }

        List<ShiftModel> shifts = snapshot.data!;
        shifts = shifts.where((shift) {
          final DateTime shiftDate = DateFormat('dd/MM/yyyy').parse(shift.date);
          return shiftDate.day == selectedDay.day &&
              shiftDate.month == selectedDay.month &&
              shiftDate.year == selectedDay.year;
        }).toList();

        if (shifts.isEmpty) {
          return _buildEmptyShiftsMessage();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: shifts
                .map((shift) => ShiftCard(
                      shift: shift,
                      shiftService: _shiftService,
                      workerService: _workerService,
                    ))
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyShiftsMessage() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_off, size: 50, color: AppColors.textSecondary),
          SizedBox(height: 10),
          Text('אין משמרות זמינות ליום זה', style: AppTheme.bodyText),
        ],
      ),
    );
  }

  Widget _buildCreateShiftButton() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: _isNavigating
          ? null
          : () async {
              setState(() => _isNavigating = true);
              final DateTime selectedDate =
                  _currentWeekStart.add(Duration(days: _tabController.index));
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        CreateShiftScreen(initialDate: selectedDate)),
              );
              if (mounted) setState(() => _isNavigating = false);
            },
      icon: const Icon(Icons.add, size: 30, color: Colors.white),
      label: const Text("יצירת משמרת", style: AppTheme.buttonTextStyle),
    );
  }
}
