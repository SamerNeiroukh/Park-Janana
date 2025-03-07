import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../services/shift_service.dart';
import '../widgets/message_bubble.dart';


class WorkerShiftCard extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;
  final User currentUser;

  const WorkerShiftCard({
    super.key,
    required this.shift,
    required this.shiftService,
    required this.currentUser,
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
          _isShiftFull =
              assignedWorkers.length >= (shiftData['maxWorkers'] ?? 0);
        });
      }
    });
  }

  void _toggleShiftRequest() async {
    if (_hasRequested) {
      await widget.shiftService
          .cancelShiftRequest(widget.shift.id, _currentUser!.uid);
    } else {
      await widget.shiftService
          .requestShift(widget.shift.id, _currentUser!.uid);
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
    DateTime shiftDate = DateFormat('dd/MM/yyyy').parse(widget.shift.date);
    bool isOutdated = shiftDate.isBefore(DateTime.now());
    Color cardColor = Colors.white.withOpacity(0.9);

    if (isOutdated) {
      cardColor = Colors.grey.shade300;
    } else if (_isAssigned) {
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
                  child: Icon(Icons.event_note,
                      color: Colors.blue.shade700, size: 30),
                ),
                if (_isAssigned)
                  _buildStatusLabel(
                      isOutdated ? "עבדת במשמרת" : "משובץ",
                      Colors.blue,
                      Icons.check_circle)
                else if (isOutdated)
                  _buildStatusLabel("עבר זמנו", Colors.grey, Icons.history)
                else if (_isShiftFull)
                  _buildStatusLabel("מלא", Colors.red, Icons.block)
                else
                  ElevatedButton(
                    onPressed: isOutdated
                        ? null
                        : (_isShiftFull && !_hasRequested
                            ? null
                            : _toggleShiftRequest),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasRequested
                          ? Colors.redAccent
                          : (_isShiftFull ? Colors.grey : Colors.green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8),
            Text(
              "שעות: ${widget.shift.startTime} - ${widget.shift.endTime}",
              style: const TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 14),

            // ✅ Ensure the details button is always displayed
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.expand_more, color: Colors.blue, size: 28),
                onPressed: _showShiftDetails,
              ),
            ),
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
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}


class ShiftDetailsPopup extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;

  const ShiftDetailsPopup({
    super.key,
    required this.shift,
    required this.shiftService,
  });

  @override
  State<ShiftDetailsPopup> createState() => _ShiftDetailsPopupState();
}

class _ShiftDetailsPopupState extends State<ShiftDetailsPopup> {
  static final Map<String, UserModel> _workerCache = {};
  static final Map<String, List<Map<String, dynamic>>> _messagesCache = {};

  late List<UserModel> assignedWorkers = [];
  bool isLoadingWorkers = true;
  bool isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedWorkers();
    _fetchShiftMessages();
  }

  // ✅ Load assigned workers (from cache or Firestore)
  Future<void> _fetchAssignedWorkers() async {
    List<UserModel> workers = [];
    for (String workerId in widget.shift.assignedWorkers) {
      if (_workerCache.containsKey(workerId)) {
        workers.add(_workerCache[workerId]!);
      } else {
        try {
          UserModel worker = await widget.shiftService.fetchWorkerDetails([workerId]).then((users) => users.first);
          _workerCache[workerId] = worker; // ✅ Cache worker details
          workers.add(worker);
        } catch (e) {
          debugPrint("Failed to fetch worker details: $e");
        }
      }
    }
    if (mounted) {
      setState(() {
        assignedWorkers = workers;
        isLoadingWorkers = false;
      });
    }
  }

  // ✅ Load messages (from cache or Firestore)
  Future<void> _fetchShiftMessages() async {
    if (_messagesCache.containsKey(widget.shift.id)) {
      setState(() {
        isLoadingMessages = false;
      });
      return;
    }

    try {
      DocumentSnapshot shiftDoc = await FirebaseFirestore.instance.collection('shifts').doc(widget.shift.id).get();
      List<Map<String, dynamic>> messages = List<Map<String, dynamic>>.from(shiftDoc['messages'] ?? []);

      _messagesCache[widget.shift.id] = messages; // ✅ Cache messages

      if (mounted) {
        setState(() {
          isLoadingMessages = false;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch shift messages: $e");
      if (mounted) {
        setState(() {
          isLoadingMessages = false;
        });
      }
    }
  }

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
                    child: isLoadingWorkers
                        ? const Center(child: CircularProgressIndicator())
                        : assignedWorkers.isEmpty
                            ? const Center(child: Text("אין עובדים מוקצים.", style: TextStyle(fontSize: 16)))
                            : ListView.separated(
                                itemCount: assignedWorkers.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.grey),
                                itemBuilder: (context, index) {
                                  UserModel worker = assignedWorkers[index];
                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                    leading: CircleAvatar(
                                      radius: 30.0,
                                      backgroundImage: worker.profilePicture.startsWith('http')
                                          ? NetworkImage(worker.profilePicture)
                                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                                    ),
                                    title: Text(
                                      worker.fullName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      textAlign: TextAlign.right,
                                    ),
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
                    child: isLoadingMessages
                        ? const Center(child: CircularProgressIndicator())
                        : (_messagesCache[widget.shift.id]?.isEmpty ?? true)
                            ? const Center(child: Text("אין הודעות זמינות.", style: TextStyle(fontSize: 16)))
                            : ListView(
                                children: _messagesCache[widget.shift.id]!
                                    .map((msg) => MessageBubble(
                                          message: msg['message'],
                                          timestamp: msg['timestamp'],
                                          senderId: msg['senderId'],
                                          shiftId: widget.shift.id,
                                        ))
                                    .toList(),
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
