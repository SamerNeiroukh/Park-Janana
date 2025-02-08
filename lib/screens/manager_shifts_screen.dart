import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart'; // ✅ Import UserModel
import '../widgets/user_header.dart';
import '../services/shift_service.dart';
import '../utils/datetime_utils.dart';
import '../widgets/date_time_picker.dart';

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
        onPressed: _showCreateShiftBottomSheet,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        child: const Text("➕ יצירת משמרת", style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildDeleteShiftButton(ShiftModel shift) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        onPressed: () => _shiftService.deleteShift(shift.id),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
        child: const Text("🗑️ מחק משמרת", style: TextStyle(color: Colors.white)),
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
          Text(
            "📅 ${shift.date} | 🏢 ${shift.department}",
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(
            "⏰ ${shift.startTime} - ${shift.endTime}",
            style: const TextStyle(fontSize: 14.0, color: Colors.white70),
          ),
          Text(
            "👥 ${shift.assignedWorkers.length} מתוך ${shift.maxWorkers} עובדים",
            style: const TextStyle(fontSize: 14.0, color: Colors.white),
          ),
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
                          trailing: isAssigned
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _shiftService.removeWorker(shift.id, worker.uid ?? ""),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.check_circle, color: Colors.green),
                                      onPressed: () => _shiftService.approveWorker(shift.id, worker.uid ?? ""),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel, color: Colors.red),
                                      onPressed: () => _shiftService.rejectWorker(shift.id, worker.uid ?? ""),
                                    ),
                                  ],
                                ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateShiftBottomSheet() {
    String selectedDepartment = "Ropes";
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    TimeOfDay selectedEndTime = TimeOfDay.now();
    int maxWorkers = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("📅 תאריך"),
              DatePickerWidget(
                initialDate: selectedDate,
                onDateSelected: (date) => selectedDate = date,
              ),
              const SizedBox(height: 10),
              const Text("⏰ זמן התחלה"),
              TimePickerWidget(
                initialTime: selectedStartTime,
                onTimeSelected: (time) => selectedStartTime = time,
              ),
              const SizedBox(height: 10),
              const Text("⏰ זמן סיום"),
              TimePickerWidget(
                initialTime: selectedEndTime,
                onTimeSelected: (time) => selectedEndTime = time,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _shiftService.createShift(
                    date: DateTimeUtils.formatDate(selectedDate),
                    startTime: DateTimeUtils.formatTime(selectedStartTime),
                    endTime: DateTimeUtils.formatTime(selectedEndTime),
                    department: selectedDepartment,
                    maxWorkers: maxWorkers,
                  );
                  Navigator.pop(context);
                },
                child: const Text("✅ צור משמרת"),
              ),
            ],
          ),
        );
      },
    );
  }
}
