import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../services/shift_service.dart';
import '../widgets/message_bubble.dart';

class WorkerShiftCard extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;

  const WorkerShiftCard({
    super.key,
    required this.shift,
    required this.shiftService,
  });

  @override
  State<WorkerShiftCard> createState() => _WorkerShiftCardState();
}

class _WorkerShiftCardState extends State<WorkerShiftCard> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _hasRequested = false;
  bool _isShiftFull = false;
  bool _isAssigned = false;

  @override
  void initState() {
    super.initState();
    _listenToShiftUpdates();
  }

  void _listenToShiftUpdates() {
    FirebaseFirestore.instance
        .collection('shifts')
        .doc(widget.shift.id)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        var shiftData = snapshot.data() as Map<String, dynamic>;
        List<dynamic> requestedWorkers = shiftData['requestedWorkers'] ?? [];
        List<dynamic> assignedWorkers = shiftData['assignedWorkers'] ?? [];

        setState(() {
          _hasRequested = requestedWorkers.contains(_currentUser?.uid);
          _isAssigned = assignedWorkers.contains(_currentUser?.uid);
          _isShiftFull = assignedWorkers.length >= (shiftData['maxWorkers'] ?? 0);
        });
      }
    });
  }

  void _toggleShiftRequest() async {
    if (_hasRequested) {
      await widget.shiftService.cancelShiftRequest(widget.shift.id, _currentUser!.uid);
    } else {
      await widget.shiftService.requestShift(widget.shift.id, _currentUser!.uid);
    }
  }

  void _showShiftDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftDetailsPopup(
        shift: widget.shift,
        shiftService: widget.shiftService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color cardColor = Colors.white.withOpacity(0.9);
    if (_isAssigned) {
      cardColor = Colors.green.shade50;
    } else if (_isShiftFull) {
      cardColor = Colors.red.shade50;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: Colors.blueAccent.withOpacity(0.3),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.event_note, color: Colors.blue.shade700, size: 30),
                ),
                _isAssigned
                    ? _buildStatusLabel("במשמרת", Colors.green, Icons.check_circle)
                    : _isShiftFull
                        ? _buildStatusLabel("מלא", Colors.red, Icons.block)
                        : ElevatedButton(
                            onPressed: _isShiftFull && !_hasRequested ? null : _toggleShiftRequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _hasRequested
                                  ? Colors.redAccent
                                  : (_isShiftFull ? Colors.grey : Colors.green),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              elevation: 4,
                            ),
                            child: Text(
                              _hasRequested ? "ביטול בקשה" : "הצטרף",
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              "${widget.shift.date} | ${widget.shift.department}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              "שעות: ${widget.shift.startTime} - ${widget.shift.endTime}",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.expand_more, color: Colors.blue, size: 28),
                onPressed: _showShiftDetails,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLabel(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}


class ShiftDetailsPopup extends StatelessWidget {
  final ShiftModel shift;
  final ShiftService shiftService;

  const ShiftDetailsPopup({
    super.key,
    required this.shift,
    required this.shiftService,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              spreadRadius: 5,
              blurRadius: 25,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                flex: 35,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("👥 עובדים מוקצים:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: shift.assignedWorkers.isEmpty
                          ? const Center(child: Text("אין עובדים מוקצים.", style: TextStyle(fontSize: 16)))
                          : ListView.separated(
                              itemCount: shift.assignedWorkers.length,
                              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                              itemBuilder: (context, index) {
                                return FutureBuilder<UserModel>(
                                  future: shiftService.fetchWorkerDetails([shift.assignedWorkers[index]])
                                      .then((users) => users.first),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(child: CircularProgressIndicator());
                                    }
                                    if (!snapshot.hasData) {
                                      return const Text("Worker not found");
                                    }

                                    return ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                      leading: CircleAvatar(
                                        radius: 30.0,
                                        backgroundImage: snapshot.data!.profilePicture.startsWith('http')
                                            ? NetworkImage(snapshot.data!.profilePicture)
                                            : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                                      ),
                                      title: Text(
                                        snapshot.data!.fullName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                        textAlign: TextAlign.right,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                flex: 65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("📩 הודעות מהמנהלים:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
                    const SizedBox(height: 12),
                    Expanded(
                      child: shift.messages.isEmpty
                          ? const Center(child: Text("אין הודעות זמינות.", style: TextStyle(fontSize: 16)))
                          : ListView(
                              children: shift.messages.map((msg) => MessageBubble(
                                    message: msg['message'],
                                    timestamp: msg['timestamp'],
                                    senderId: msg['senderId'],
                                    shiftId: shift.id,
                                  )).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
