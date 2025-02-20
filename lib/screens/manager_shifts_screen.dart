import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../widgets/user_header.dart';
import '../services/shift_service.dart';
import '../services/worker_service.dart';
import '../screens/create_shift_screen.dart';
import '../widgets/shift_card.dart';
import '../utils/datetime_utils.dart';

class ManagerShiftsScreen extends StatefulWidget {
  const ManagerShiftsScreen({super.key});

  @override
  State<ManagerShiftsScreen> createState() => _ManagerShiftsScreenState();
}

class _ManagerShiftsScreenState extends State<ManagerShiftsScreen> {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();

  String _sortOption = 'תאריך'; // ✅ Default to 'תאריך' (Date)
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // ✅ Right-to-Left layout
      child: Scaffold(
        body: Column(
          children: [
            const UserHeader(),
            _buildCreateShiftButton(),
            _buildSortOptions(),
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
                        'אין משמרות זמינות כרגע.',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    );
                  }

                  List<ShiftModel> shifts = snapshot.data!;
                  shifts = _shiftService.sortShifts(shifts, _sortOption);

                  Map<String, List<ShiftModel>> groupedShifts = {};
                  for (var shift in shifts) {
                    String groupKey = _sortOption == 'תאריך'
                        ? DateTimeUtils.formatDateWithDay(shift.date)
                        : 'מחלקה: ${shift.department}';

                    if (!groupedShifts.containsKey(groupKey)) {
                      groupedShifts[groupKey] = [];
                    }
                    groupedShifts[groupKey]!.add(shift);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: groupedShifts.entries.map((entry) {
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
      ),
    );
  }

  // ✅ Create Shift Button in Hebrew
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

  // ✅ Sort Options: Only "תאריך" and "מחלקה"
  Widget _buildSortOptions() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: DropdownButton<String>(
  value: ['תאריך', 'מחלקה'].contains(_sortOption) ? _sortOption : 'תאריך',
  items: ['תאריך', 'מחלקה'].map((String value) {
    return DropdownMenuItem<String>(
      value: value,
      child: Text("מיון לפי $value"),
    );
  }).toList(),
  onChanged: (newValue) {
    setState(() {
      _sortOption = newValue!;
    });
  },
),
  );
}
}
