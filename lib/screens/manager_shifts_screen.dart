import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../widgets/user_header.dart';
import '../services/shift_service.dart';
import '../services/worker_service.dart';
import '../screens/create_shift_screen.dart';
import '../widgets/shift_card.dart'; // ✅ Import new shift card widget

class ManagerShiftsScreen extends StatefulWidget {
  const ManagerShiftsScreen({super.key});

  @override
  State<ManagerShiftsScreen> createState() => _ManagerShiftsScreenState();
}

class _ManagerShiftsScreenState extends State<ManagerShiftsScreen> {
  final ShiftService _shiftService = ShiftService();
  final WorkerService _workerService = WorkerService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
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
                      'אין משמרות זמינות כרגע.',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  );
                }

                List<ShiftModel> shifts = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: shifts.length,
                  itemBuilder: (context, index) {
                    return ShiftCard(
                      shift: shifts[index],
                      shiftService: _shiftService,
                      workerService: _workerService,
                    ); // ✅ Uses new ShiftCard widget
                  },
                );
              },
            ),
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
