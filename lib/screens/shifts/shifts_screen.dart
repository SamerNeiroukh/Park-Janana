import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../services/shift_service.dart';
import '../../widgets/user_header.dart';
import '../../widgets/worker_shift_card.dart';


class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final ShiftService _shiftService = ShiftService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  

  // ✅ Ensure the week starts from Sunday
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday % 7));
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserHeader(),
      body: Column(
        children: [
          _buildWeekNavigation(),
          _buildDayTabs(),
          Expanded(child: _buildShiftList()),
        ],
      ),
    );
  }

  // 🟢 Week Navigation
  Widget _buildWeekNavigation() {
    String weekRange = "${DateFormat('MMM dd').format(_currentWeekStart)} - ${DateFormat('MMM dd').format(_currentWeekStart.add(const Duration(days: 6)))}";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
              });
            },
          ),
          Text(
            weekRange,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
              });
            },
          ),
        ],
      ),
    );
  }

  // 🟢 Day Tabs (Sunday - Saturday)
  Widget _buildDayTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        DateTime day = _currentWeekStart.add(Duration(days: index));
        bool isSelected = _selectedDay.day == day.day && _selectedDay.month == day.month;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = day;
            });
          },
          child: Column(
            children: [
              Text(
                DateFormat('E').format(day),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
              Text(
                DateFormat('dd').format(day),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue : Colors.black,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // 🟢 Build Shift List
  Widget _buildShiftList() {
    return StreamBuilder<List<ShiftModel>>(
      stream: _shiftService.getShiftsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('אין משמרות זמינות כרגע.'));
        }

        // 🟢 Filter shifts for the selected day
        final filteredShifts = snapshot.data!.where((shift) {
          return shift.date == DateFormat('dd/MM/yyyy').format(_selectedDay);
        }).toList();

        if (filteredShifts.isEmpty) {
          return const Center(child: Text('אין משמרות ליום זה.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: filteredShifts.length,
          itemBuilder: (context, index) {
            return WorkerShiftCard(
              shift: filteredShifts[index],
              shiftService: _shiftService,
              currentUser: _currentUser!,
            );
          },
        );
      },
    );
  }
}
