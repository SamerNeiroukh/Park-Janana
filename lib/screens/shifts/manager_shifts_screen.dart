import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_model.dart';
import '../../widgets/user_header.dart';
import '../../services/shift_service.dart';
import '../../services/worker_service.dart';
import 'create_shift_screen.dart';
import '../../widgets/shift_card.dart';
import '../../utils/datetime_utils.dart';

class ManagerShiftsScreen extends StatefulWidget {
  const ManagerShiftsScreen({super.key});

  @override
  State<ManagerShiftsScreen> createState() => _ManagerShiftsScreenState();
}

class _ManagerShiftsScreenState extends State<ManagerShiftsScreen> with SingleTickerProviderStateMixin {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();
  late TabController _tabController;
  DateTime _currentWeekStart = DateTimeUtils.startOfWeek(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light background for a modern look
      body: Column(
        children: [
          const UserHeader(),
          _buildWeekNavigation(),
          _buildTabBar(),
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: List.generate(7, (index) {
                    DateTime day = _currentWeekStart.add(Duration(days: index));
                    return _buildShiftList(day);
                  }),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: _buildCreateShiftButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📆 **Navigation Between Weeks**
  Widget _buildWeekNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue, size: 28),
            onPressed: () => setState(() {
              _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
            }),
          ),
          Expanded(
            child: Text(
              "${DateTimeUtils.formatDate(_currentWeekStart)} - ${DateTimeUtils.formatDate(_currentWeekStart.add(const Duration(days: 6)))}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
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

  /// 📅 **Tab Bar for Weekly Navigation**
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black54,
        indicator: BoxDecoration(
          color: Colors.blue.shade700,
          borderRadius: BorderRadius.circular(12),
        ),
        isScrollable: true,
        tabs: List.generate(7, (index) {
          DateTime day = _currentWeekStart.add(Duration(days: index));
          return Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              child: Text(
                DateTimeUtils.getHebrewWeekdayName(day.weekday),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 📆 **Shift List for Selected Day**
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
          DateTime shiftDate = DateFormat('dd/MM/yyyy').parse(shift.date);
          return shiftDate.day == selectedDay.day &&
                 shiftDate.month == selectedDay.month &&
                 shiftDate.year == selectedDay.year;
        }).toList();

        if (shifts.isEmpty) {
          return _buildEmptyShiftsMessage();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 70), // ✅ Prevents FAB from covering shifts
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: shifts.map((shift) => ShiftCard(
              shift: shift,
              shiftService: _shiftService,
              workerService: _workerService,
            )).toList(),
          ),
        );
      },
    );
  }

  /// 🚫 **Display "No Shifts" Message**
  Widget _buildEmptyShiftsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.work_off, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          const Text(
            'אין משמרות זמינות ליום זה.',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  /// ➕ **Floating Action Button for Creating a Shift**
  Widget _buildCreateShiftButton() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.blue.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CreateShiftScreen()),
        );
      },
      icon: const Icon(Icons.add, size: 30, color: Colors.white),
      label: const Text("יצירת משמרת", style: TextStyle(fontSize: 16, color: Colors.white)),
    );
  }
}
