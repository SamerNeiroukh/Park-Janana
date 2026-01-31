import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../services/shift_service.dart';
import '../widgets/message_bubble.dart';
import 'package:park_janana/utils/profile_image_provider.dart';

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
        final shiftData = snapshot.data() as Map<String, dynamic>;
        final List<dynamic> requestedWorkers =
            shiftData['requestedWorkers'] ?? [];
        final List<dynamic> assignedWorkers =
            shiftData['assignedWorkers'] ?? [];

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
    final DateTime shiftDate =
        DateFormat('dd/MM/yyyy').parse(widget.shift.date);
    final bool isOutdated = shiftDate.isBefore(DateTime.now());
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
                  _buildStatusLabel(isOutdated ? "עבדת במשמרת" : "משובץ",
                      Colors.blue, Icons.check_circle)
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
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon:
                    const Icon(Icons.expand_more, color: Colors.blue, size: 28),
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
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
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

  late List<UserModel> assignedWorkers = [];
  bool isLoadingWorkers = true;

  @override
  void initState() {
    super.initState();
    _fetchAssignedWorkers();
  }

  Future<void> _fetchAssignedWorkers() async {
    final List<UserModel> workers = [];
    for (String workerId in widget.shift.assignedWorkers) {
      if (_workerCache.containsKey(workerId)) {
        workers.add(_workerCache[workerId]!);
      } else {
        try {
          final UserModel worker = await widget.shiftService
              .fetchWorkerDetails([workerId]).then((users) => users.first);
          _workerCache[workerId] = worker;
          workers.add(worker);
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        assignedWorkers = workers;
        isLoadingWorkers = false;
      });
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
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          color: Colors.white,
        ),
        child: ListView(
          controller: controller,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            /// 👥 Workers (compact)
            const Text("👥 עובדים מוקצים",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 12),
            isLoadingWorkers
                ? const Center(child: CircularProgressIndicator())
                : assignedWorkers.isEmpty
                    ? const Text("אין עובדים מוקצים")
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: assignedWorkers.map((worker) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FutureBuilder<ImageProvider>(
                                future: ProfileImageProvider.resolve(
                                  storagePath: worker.profilePicturePath,
                                  fallbackUrl: worker.profilePicture,
                                ),
                                builder: (context, snapshot) {
                                  return CircleAvatar(
                                    radius: 26,
                                    backgroundImage: snapshot.data,
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(worker.fullName,
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          );
                        }).toList(),
                      ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            /// 💬 Messages (full space)
            const Text("📩 הודעות",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shifts')
                  .doc(widget.shift.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final messages =
                    List<Map<String, dynamic>>.from(data['messages'] ?? []);

                if (messages.isEmpty) {
                  return const Text("אין הודעות זמינות");
                }

                return Column(
                  children: messages.map((msg) {
                    return MessageBubble(
                      message: msg['message'],
                      timestamp: msg['timestamp'],
                      senderId: msg['senderId'],
                      shiftId: widget.shift.id,
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
