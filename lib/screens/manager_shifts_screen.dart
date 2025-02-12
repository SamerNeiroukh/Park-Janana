import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../widgets/user_header.dart';
import '../services/shift_service.dart';
import '../screens/create_shift_screen.dart';

class ManagerShiftsScreen extends StatefulWidget {
  const ManagerShiftsScreen({super.key});

  @override
  State<ManagerShiftsScreen> createState() => _ManagerShiftsScreenState();
}

class _ManagerShiftsScreenState extends State<ManagerShiftsScreen> {
  final ShiftService _shiftService = ShiftService();

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
                    final shift = shifts[index];

                    return Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ExpansionTile(
                        iconColor: Colors.blue.shade700,
                        collapsedIconColor: Colors.blue.shade700,
                        title: _buildShiftHeader(shift),
                        children: [
                          _buildWorkerList("👥 עובדים מוקצים", shift.assignedWorkers, shift, isAssigned: true),
                          _buildWorkerList("🕐 בקשות למשמרת", shift.requestedWorkers, shift, isAssigned: false),
                          _buildDeleteShiftButton(shift),
                        ],
                      ),
                    );
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

  Widget _buildShiftHeader(ShiftModel shift) {
    bool isFull = shift.assignedWorkers.length >= shift.maxWorkers;
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isFull ? [Colors.red.shade400, Colors.red.shade700] : [Colors.green.shade400, Colors.green.shade700],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📅 ${shift.date} | 🏢 ${shift.department}", style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white)),
          Text("⏰ ${shift.startTime} - ${shift.endTime}", style: const TextStyle(fontSize: 14.0, color: Colors.white70)),
          Text("👥 ${shift.assignedWorkers.length} מתוך ${shift.maxWorkers} עובדים", style: const TextStyle(fontSize: 14.0, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildWorkerList(String title, List<String> workers, ShiftModel shift, {required bool isAssigned}) {
    return FutureBuilder<List<UserModel>>(
      future: _shiftService.fetchWorkerDetails(workers),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<UserModel>? workerDetails = snapshot.data;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: isAssigned ? Colors.green.shade700 : Colors.orange.shade700),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              (workerDetails == null || workerDetails.isEmpty)
                  ? const Text("אין בקשות למשמרת זו.")
                  : Column(
                      children: workerDetails.map((worker) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: (worker.profilePicture != null && worker.profilePicture!.isNotEmpty)
                                ? NetworkImage(worker.profilePicture!)
                                : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                          ),
                          title: Text(worker.fullName ?? "לא ידוע"),
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeleteShiftButton(ShiftModel shift) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () async {
          await _shiftService.deleteShift(shift.id);
          setState(() {}); // Refresh UI after deletion
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
        child: const Text("🗑️ מחק משמרת", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
