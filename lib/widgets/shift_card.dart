import 'package:flutter/material.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../services/shift_service.dart';
import '../services/worker_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/message_bubble.dart';
import '../widgets/worker_row.dart';

class ShiftCard extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;
  final WorkerService workerService;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.shiftService,
    required this.workerService,
  });

  @override
  ShiftCardState createState() => ShiftCardState();
}

class ShiftCardState extends State<ShiftCard> {
  final TextEditingController _messageController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<String> _approvedWorkers =
      []; // ✅ Temporary list to store approved workers

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      shadowColor: Colors.grey.withOpacity(0.5),
      child: ExpansionTile(
        iconColor: Colors.blue.shade700,
        collapsedIconColor: Colors.blue.shade700,
        title: _buildShiftHeader(),
        children: [
          if (_approvedWorkers.isNotEmpty) _buildSubmitButton(),
          _buildWorkerList("🕐 בקשות למשמרת", widget.shift.requestedWorkers,
              isAssigned: false),
          _buildWorkerList("👥 עובדים מוקצים", widget.shift.assignedWorkers,
              isAssigned: true),
          _buildMessagesSection(),
          _buildAddMessageSection(),
          _buildDeleteShiftButton(context),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: _submitApprovedWorkers,
        child: const Text("✅ אשר עובדים למשמרת",
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildShiftHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.blue.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("📅 ${widget.shift.date} | 🏢 ${widget.shift.department}",
              style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text("⏰ ${widget.shift.startTime} - ${widget.shift.endTime}",
              style: const TextStyle(fontSize: 14.0, color: Colors.white70)),
          Text(
              "👥 עובדים מוקצים: ${widget.shift.assignedWorkers.length}/${widget.shift.maxWorkers}",
              style: const TextStyle(fontSize: 14.0, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildWorkerList(String title, List<String> workers,
    {required bool isAssigned}) {
  return Directionality(
    textDirection: TextDirection.rtl,
    child: FutureBuilder<List<UserModel>>(
      future: widget.shiftService.fetchWorkerDetails(workers),
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
            border: Border.all(
                color: isAssigned ? Colors.green.shade700 : Colors.orange.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(),
              (workerDetails == null || workerDetails.isEmpty)
                  ? const Align(
                      alignment: Alignment.centerRight,
                      child: Text("אין בקשות למשמרת זו."),
                    )
                  : Column(
                      children: workerDetails.map((worker) {
                        return WorkerRow(
                          worker: worker,
                          shiftId: widget.shift.id,
                          isAssigned: isAssigned,
                          workerService: widget.workerService,
                          isApproved: _approvedWorkers.contains(worker.uid),
                          onApproveToggle: (bool isApproved) {
                            setState(() {
                              if (isApproved) {
                                _approvedWorkers.add(worker.uid);
                              } else {
                                _approvedWorkers.remove(worker.uid);
                              }
                            });
                          },
                          showRemoveIcon: isAssigned, // ✅ Fix: Allow remove for assigned workers only
                        );
                      }).toList(),
                    ),
            ],
          ),
        );
      },
    ),
  );
}

  Widget _buildMessagesSection() {
    return Directionality(
      textDirection: TextDirection.rtl, // ✅ Align messages Right
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.end, // ✅ Align text & labels to right
          children: [
            Align(
              alignment:
                  Alignment.centerRight, // ✅ Moves label fully to the right
              child: const Text(
                "📩 הודעות מנהלים:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (widget.shift.messages.isEmpty)
              Align(
                alignment:
                    Alignment.centerRight, // ✅ Aligns empty message properly
                child: const Text("אין הודעות זמינות."),
              ),
            ...widget.shift.messages.map((msg) {
              return MessageBubble(
                message: msg['message'] ?? "אין תוכן",
                timestamp:
                    msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
                senderId: msg['senderId'] ?? "",
                shiftId: widget.shift.id,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMessageSection() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          TextField(
            controller: _messageController,
            decoration: InputDecoration(
              labelText: "הוסף הודעה למשמרת",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 10.0),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
            ),
            onPressed: _addMessage,
            child: const Text("📩 שלח הודעה",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteShiftButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: () async {
          await widget.shiftService.deleteShift(widget.shift.id);
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text("🗑️ משמרת נמחקה")));
          }
        },
        child:
            const Text("🗑️ מחק משמרת", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addMessage() async {
    if (_messageController.text.isNotEmpty && _currentUser != null) {
      await widget.shiftService.addMessageToShift(
          widget.shift.id, _messageController.text, _currentUser.uid ?? '');
      _messageController.clear();
      setState(() {});
    }
  }

  void _submitApprovedWorkers() async {
    if (_approvedWorkers.isNotEmpty) {
      await widget.workerService
          .bulkApproveWorkers(widget.shift.id, _approvedWorkers);
      setState(() {
        _approvedWorkers.clear();
      });
    }
  }
}
