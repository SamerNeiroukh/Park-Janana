import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shift_model.dart';
import '../widgets/user_header.dart';

class ShiftsScreen extends StatefulWidget {
  const ShiftsScreen({super.key});

  @override
  State<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends State<ShiftsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _requestShift(String shiftId) async {
    if (_currentUser == null) return;

    try {
      DocumentReference shiftRef =
          FirebaseFirestore.instance.collection('shifts').doc(shiftId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot shiftSnapshot = await transaction.get(shiftRef);
        if (!shiftSnapshot.exists) return;

        Map<String, dynamic> shiftData =
            shiftSnapshot.data() as Map<String, dynamic>;

        List<String> requestedWorkers =
            List<String>.from(shiftData['requestedWorkers'] ?? []);

        if (!requestedWorkers.contains(_currentUser!.uid) &&
            requestedWorkers.length < shiftData['maxWorkers']) {
          requestedWorkers.add(_currentUser!.uid);
          transaction.update(shiftRef, {'requestedWorkers': requestedWorkers});
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error requesting shift: $e');
    }
  }

  Future<void> _cancelShiftRequest(String shiftId) async {
    if (_currentUser == null) return;

    try {
      DocumentReference shiftRef =
          FirebaseFirestore.instance.collection('shifts').doc(shiftId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot shiftSnapshot = await transaction.get(shiftRef);
        if (!shiftSnapshot.exists) return;

        Map<String, dynamic> shiftData =
            shiftSnapshot.data() as Map<String, dynamic>;

        List<String> requestedWorkers =
            List<String>.from(shiftData['requestedWorkers'] ?? []);

        if (requestedWorkers.contains(_currentUser!.uid)) {
          requestedWorkers.remove(_currentUser!.uid);
          transaction.update(shiftRef, {'requestedWorkers': requestedWorkers});
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error canceling shift request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(), // ✅ Keep consistency with HomeScreen
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('shifts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'אין משמרות זמינות כרגע.',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  );
                }

                List<ShiftModel> shifts = snapshot.data!.docs.map((doc) {
                  return ShiftModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
                }).toList();

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
                                        : (isShiftFull ? Colors.grey : Colors.green.shade600), // ✅ Green join button
                                    elevation: 4,
                                    minimumSize: const Size(200, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22.0), // ✅ Balanced button radius
                                    ),
                                  ),
                                  onPressed: isShiftFull
                                      ? null
                                      : () {
                                          if (hasRequested) {
                                            _cancelShiftRequest(shift.id);
                                          } else {
                                            _requestShift(shift.id);
                                          }
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
          Icon(icon, color: Colors.blueGrey.shade700), // ✅ Darker icon for contrast
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
