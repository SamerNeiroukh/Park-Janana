import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'create_shift_screen.dart';
import 'package:park_janana/features/shifts/widgets/shift_card.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';

class ManagerWeekView extends StatefulWidget {
  const ManagerWeekView({super.key});

  @override
  State<ManagerWeekView> createState() => _ManagerWeekViewState();
}

class _ManagerWeekViewState extends State<ManagerWeekView> {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();

  DateTime _currentWeekStart = DateTimeUtils.startOfWeek(DateTime.now());
  bool _isNavigating = false; // ✅ Prevent multiple taps

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            _buildWeekNavigation(),
          _buildCreateShiftButton(),
          Expanded(
            child: StreamBuilder<List<ShiftModel>>(
              stream: _shiftService.getShiftsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'אין משמרות זמינות לשבוע זה',
                      style: AppTheme.bodyText,
                    ),
                  );
                }

                List<ShiftModel> shifts = snapshot.data!;
                shifts = shifts.where((shift) {
                  final DateTime shiftDate =
                      DateFormat('dd/MM/yyyy').parse(shift.date);
                  return shiftDate.isAfter(_currentWeekStart
                          .subtract(const Duration(days: 1))) &&
                      shiftDate.isBefore(
                          _currentWeekStart.add(const Duration(days: 7)));
                }).toList();

                final Map<String, List<ShiftModel>> weeklyShifts = {};
                for (var shift in shifts) {
                  final String dayLabel =
                      DateTimeUtils.formatDateWithDay(shift.date);
                  if (!weeklyShifts.containsKey(dayLabel)) {
                    weeklyShifts[dayLabel] = [];
                  }
                  weeklyShifts[dayLabel]!.add(shift);
                }

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: weeklyShifts.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.key,
                            style: AppTheme.sectionTitle
                                .copyWith(color: AppColors.primary)),
                        ...entry.value.map((shift) => ShiftCard(
                              shift: shift,
                              shiftService: _shiftService,
                              workerService: _workerService,
                            )),
                        const SizedBox(height: 16),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildWeekNavigation() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
            iconSize: 28,
            onPressed: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.subtract(const Duration(days: 7));
            }),
          ),
          Text(
            "שבוע ${DateTimeUtils.formatDate(_currentWeekStart)} - ${DateTimeUtils.formatDate(_currentWeekStart.add(const Duration(days: 6)))}",
            style: AppTheme.sectionTitle,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            color: AppColors.primary,
            iconSize: 28,
            onPressed: () => setState(() {
              _currentWeekStart =
                  _currentWeekStart.add(const Duration(days: 7));
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateShiftButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: ElevatedButton(
        onPressed: _isNavigating
            ? null
            : () async {
                setState(() => _isNavigating = true);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateShiftScreen()),
                );
                if (mounted) setState(() => _isNavigating = false);
              },
        style: AppTheme.primaryButtonStyle,
        child: const Text("יצירת משמרת"),
      ),
    );
  }
}
