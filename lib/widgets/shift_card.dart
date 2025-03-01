import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
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

  final List<String> _approvedWorkers = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      shadowColor: AppColors.cardShadow,
      child: ExpansionTile(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.primary,
        title: _buildShiftHeader(),
        children: [
          if (_approvedWorkers.isNotEmpty) _buildSubmitButton(),
          _buildWorkerList("🕐 בקשות למשמרת", widget.shift.requestedWorkers, isAssigned: false),
          _buildWorkerList("👥 עובדים מוקצים", widget.shift.assignedWorkers, isAssigned: true),
          _buildMessagesSection(),
          _buildAddMessageSection(),
          _buildDeleteShiftButton(),
        ],
      ),
    );
  }

  Widget _buildShiftHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📅 ${widget.shift.date} | 🏢 ${widget.shift.department}",
            style: AppTheme.bodyText.copyWith(color: AppColors.onPrimary, fontWeight: FontWeight.bold),
          ),
          Text(
            "⏰ ${widget.shift.startTime} - ${widget.shift.endTime}",
            style: AppTheme.bodyText.copyWith(color: Colors.white70),
          ),
          Text(
            "👥 עובדים מוקצים: ${widget.shift.assignedWorkers.length}/${widget.shift.maxWorkers}",
            style: AppTheme.bodyText.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(String title, List<String> workers, {required bool isAssigned}) {
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
              border: Border.all(color: isAssigned ? AppColors.success : AppColors.secondary),
              color: AppColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    title,
                    style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                  ),
                ),
                const Divider(),
                (workerDetails == null || workerDetails.isEmpty)
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Text("אין בקשות למשמרת זו.", style: AppTheme.bodyText),
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
                                isApproved ? _approvedWorkers.add(worker.uid) : _approvedWorkers.remove(worker.uid);
                              });
                            },
                            showRemoveIcon: isAssigned,
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
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("📩 הודעות מנהלים:", style: AppTheme.sectionTitle),
            if (widget.shift.messages.isEmpty)
              Text("אין הודעות זמינות.", style: AppTheme.bodyText),
            ...widget.shift.messages.map((msg) {
              return MessageBubble(
                message: msg['message'] ?? "אין תוכן",
                timestamp: msg['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
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
            decoration: AppTheme.inputDecoration(hintText: "הוסף הודעה למשמרת"),
          ),
          const SizedBox(height: 10.0),
          ElevatedButton(
            style: AppTheme.primaryButtonStyle,
            onPressed: _addMessage,
            child: const Text("📩 שלח הודעה"),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: _submitApprovedWorkers,
        child: const Text("✅ אשר עובדים למשמרת", style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildDeleteShiftButton() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: _deleteShift,
        child: const Text("🗑️ מחק משמרת", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addMessage() async {
    if (_messageController.text.isNotEmpty && _currentUser != null) {
      await widget.shiftService.addMessageToShift(widget.shift.id, _messageController.text, _currentUser!.uid);
      _messageController.clear();
      setState(() {});
    }
  }

  void _submitApprovedWorkers() async {
    if (_approvedWorkers.isNotEmpty) {
      await widget.workerService.bulkApproveWorkers(widget.shift.id, _approvedWorkers);
      setState(() {
        _approvedWorkers.clear();
      });
    }
  }

  void _deleteShift() async {
    await widget.shiftService.deleteShift(widget.shift.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🗑️ משמרת נמחקה")));
    }
  }
}
