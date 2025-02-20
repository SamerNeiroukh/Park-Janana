import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/shift_model.dart';
import '../../widgets/user_header.dart';
import '../../services/shift_service.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final ShiftService _shiftService = ShiftService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(), // ✅ Unified user header
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
                    bool isShiftFull = shift.requestedWorkers.length >= shift.maxWorkers;
                    bool hasRequested = shift.requestedWorkers.contains(_currentUser?.uid);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100, // ✅ Soft blue for shift card
                        borderRadius: BorderRadius.circular(18.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6.0,
                            spreadRadius: 2.0,
                            offset: const Offset(3, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShiftInfoRow(Icons.date_range, 'תאריך: ${shift.date}'),
                              _buildShiftInfoRow(Icons.business, 'מחלקה: ${shift.department}'),
                              _buildShiftInfoRow(Icons.access_time, 'שעות: ${shift.startTime} - ${shift.endTime}'),
                              _buildShiftInfoRow(Icons.people, 'מקומות פנויים: ${shift.maxWorkers - shift.requestedWorkers.length} מתוך ${shift.maxWorkers}'),
                              const SizedBox(height: 12.0),
                              Align(
                                alignment: Alignment.center,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasRequested
                                        ? Colors.redAccent
                                        : (isShiftFull ? Colors.grey : Colors.green.shade600),
                                    elevation: 4,
                                    minimumSize: const Size(200, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22.0),
                                    ),
                                  ),
                                  onPressed: isShiftFull
                                      ? null
                                      : () {
                                          if (hasRequested) {
                                            _shiftService.cancelShiftRequest(shift.id, _currentUser!.uid);
                                          } else {
                                            _shiftService.requestShift(shift.id, _currentUser!.uid);
                                          }
                                          setState(() {});
                                        },
                                  child: Text(
                                    hasRequested ? 'ביטול בקשה' : 'אני רוצה במשמרת',
                                    style: const TextStyle(fontSize: 18.0, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Widget _buildShiftInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueGrey.shade700),
          const SizedBox(width: 8.0),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
