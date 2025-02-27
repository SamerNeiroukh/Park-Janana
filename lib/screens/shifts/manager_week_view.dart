import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../widgets/user_header.dart';
import '../../services/shift_service.dart';
import '../../services/worker_service.dart';
import 'create_shift_screen.dart';
import '../../widgets/shift_card.dart';
import '../../utils/datetime_utils.dart';

class ManagerWeekView extends StatefulWidget {
  const ManagerWeekView({super.key});

  @override
  State<ManagerWeekView> createState() => _ManagerWeekViewState();
}

class _ManagerWeekViewState extends State<ManagerWeekView> {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();

  DateTime _currentWeekStart = DateTimeUtils.startOfWeek(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
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
                      'אין משמרות זמינות לשבוע זה.',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  );
                }

                List<ShiftModel> shifts = snapshot.data!;
                shifts = shifts.where((shift) {
                  DateTime shiftDate = DateFormat('dd/MM/yyyy').parse(shift.date);
                  return shiftDate.isAfter(_currentWeekStart.subtract(const Duration(days: 1))) &&
                         shiftDate.isBefore(_currentWeekStart.add(const Duration(days: 7)));
                }).toList();

                Map<String, List<ShiftModel>> weeklyShifts = {};
                for (var shift in shifts) {
                  String dayLabel = DateTimeUtils.formatDateWithDay(shift.date);
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
                        Text(
                          entry.key,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
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
    );
  }

  Widget _buildWeekNavigation() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue, size: 28),
            onPressed: () => setState(() {
              _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
            }),
          ),
          Text(
            "שבוע ${DateTimeUtils.formatDate(_currentWeekStart)} - ${DateTimeUtils.formatDate(_currentWeekStart.add(const Duration(days: 6)))}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.blue, size: 28),
            onPressed: () => setState(() {
              _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateShiftScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        child: const Text("➕ יצירת משמרת", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
