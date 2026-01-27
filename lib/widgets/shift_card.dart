import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/screens/users_screen.dart';
import '../models/shift_model.dart';
import '../models/user_model.dart';
import '../services/shift_service.dart';
import '../services/worker_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/message_bubble.dart';
import 'package:park_janana/utils/profile_image_provider.dart';

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

  static final Map<String, UserModel> _workerCache =
      {}; // ✅ Cache for worker details
  Stream<List<Map<String, dynamic>>> _getShiftMessages(String shiftId) {
    return FirebaseFirestore.instance
        .collection('shifts')
        .doc(shiftId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return [];
      return List<Map<String, dynamic>>.from(
          snapshot.data()!['messages'] ?? []);
    });
  }

  void _showCommentBottomSheet(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: const [
                  Icon(Icons.chat_rounded, color: Color(0xFF1976D2), size: 28),
                  SizedBox(width: 10),
                  Text(
                    "הודעה למשמרת",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: "כתוב את הודעתך כאן...",
                  hintTextDirection: TextDirection.rtl,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF1976D2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0xFF1976D2), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  if (controller.text.isNotEmpty && _currentUser != null) {
                    await widget.shiftService.addMessageToShift(
                      widget.shift.id,
                      controller.text,
                      _currentUser!.uid,
                    );
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white),
                label: const Text(
                  "שלח הודעה",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
          _buildWorkerList("🕐 בקשות למשמרת", widget.shift.requestedWorkers,
              isAssigned: false),
          _buildWorkerList("👥 עובדים מוקצים", widget.shift.assignedWorkers,
              isAssigned: true),
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
            style: AppTheme.bodyText.copyWith(
                color: AppColors.onPrimary, fontWeight: FontWeight.bold),
          ),
          Text(
            "⏰ ${widget.shift.startTime} - ${widget.shift.endTime}",
            style: AppTheme.bodyText.copyWith(color: Colors.white70),
          ),
          Text(
            "👥 עובדים מוקצים ${widget.shift.assignedWorkers.length}/${widget.shift.maxWorkers}",
            style: AppTheme.bodyText.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerList(String title, List<String> workerIds,
      {required bool isAssigned}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FutureBuilder<List<UserModel>>(
        future:
            _fetchWorkerDetailsWithCache(workerIds), // ✅ Uses cached function
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<UserModel>? workers = snapshot.data;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                  color: isAssigned ? AppColors.success : AppColors.secondary),
              color: AppColors.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (isAssigned)
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 4.0),
                          minimumSize: const Size(40, 36),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UsersScreen(
                                shiftId: widget.shift.id,
                                assignedWorkerIds: widget.shift.assignedWorkers,
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 18),
                            SizedBox(width: 4),
                            Text("עובדים", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                  ],
                ),
                const Divider(),
                (workers == null || workers.isEmpty)
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Text("אין עובדים מוקצים למשמרת זו",
                            style: AppTheme.bodyText),
                      )
                    : Column(
                        children: workers.map((worker) {
                          return ListTile(
                            leading: FutureBuilder<ImageProvider>(
                              future: ProfileImageProvider.resolve(
                                storagePath: worker.profilePicturePath,
                                fallbackUrl: worker.profilePicture,
                              ),
                              builder: (context, snapshot) {
                                return CircleAvatar(
                                  backgroundImage: snapshot.data,
                                );
                              },
                            ),
                            title: Text(worker.fullName,
                                textAlign: TextAlign.right),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isAssigned)
                                  IconButton(
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () => _approveWorker(worker.uid),
                                  ),
                                if (isAssigned)
                                  IconButton(
                                    icon: const Icon(Icons.undo,
                                        color: Colors.orange),
                                    onPressed: () =>
                                        _moveWorkerBack(worker.uid),
                                  ),
                                if (isAssigned)
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _removeWorker(worker.uid),
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
      ),
    );
  }

  void _approveWorker(String workerId) async {
    await widget.workerService.approveWorker(widget.shift.id, workerId);
  }

  void _moveWorkerBack(String workerId) async {
    await widget.workerService
        .moveWorkerBackToRequested(widget.shift.id, workerId);
  }

  void _removeWorker(String workerId) async {
    await widget.workerService.removeWorker(widget.shift.id, workerId);
  }

  Future<List<UserModel>> _fetchWorkerDetailsWithCache(
      List<String> workerIds) async {
    List<UserModel> workers = [];

    for (String id in workerIds) {
      if (_workerCache.containsKey(id)) {
        workers.add(_workerCache[id]!);
      } else {
        UserModel? user = await widget.workerService.getUserDetails(id);
        if (user != null) {
          // ✅ Ensure user is not null before adding
          _workerCache[id] = user;
          workers.add(user);
        }
      }
    }
    return workers;
  }

  Widget _buildMessagesSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getShiftMessages(widget.shift.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final messages = snapshot.data ?? [];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("📩 הודעות מנהלים", style: AppTheme.sectionTitle),
              if (messages.isEmpty)
                Text("אין הודעות זמינות", style: AppTheme.bodyText),
              ...messages.map((msg) {
                return MessageBubble(
                  message: msg['message'],
                  timestamp: msg['timestamp'],
                  senderId: msg['senderId'],
                  shiftId: widget.shift.id,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMessageSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: () => _showCommentBottomSheet(context),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.chat_bubble_outline, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "הוסף/נהל הודעות",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: _submitApprovedWorkers,
        child: const Text("✅ אשר עובדים למשמרת",
            style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  Widget _buildDeleteShiftButton() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        onPressed: _deleteShift,
        child:
            const Text("🗑️ מחק משמרת", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _addMessage() async {
    if (_messageController.text.isNotEmpty && _currentUser != null) {
      await widget.shiftService.addMessageToShift(
          widget.shift.id, _messageController.text, _currentUser.uid);
      _messageController.clear();
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

  void _deleteShift() async {
    await widget.shiftService.deleteShift(widget.shift.id);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("🗑️ משמרת נמחקה")));
    }
  }
}
