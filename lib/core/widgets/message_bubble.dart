import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final int timestamp;
  final String senderId;
  final String shiftId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.senderId,
    required this.shiftId,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final ShiftService _shiftService = ShiftService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isEditing = false;
  final TextEditingController _messageController = TextEditingController();

  String? _currentUserId;
  String? _currentUserRole;

  String senderName = "מנהל";
  String? profilePicturePath;
  String? profilePictureUrl;

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.message;
    _getCurrentUser();
    _getSenderData();
  }

  Future<void> _getCurrentUser() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      _currentUserId = user.uid;
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        _currentUserRole = userDoc['role'];
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _getSenderData() async {
    final userDoc = await FirebaseService().getUser(widget.senderId);
    if (userDoc.exists) {
      final userData = userDoc.data() as Map<String, dynamic>;
      senderName = userData['fullName'] ?? "מנהל";
      profilePicturePath = userData['profile_picture_path'];
      profilePictureUrl = userData['profile_picture'];
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final DateTime messageTime =
        DateTime.fromMillisecondsSinceEpoch(widget.timestamp);
    final String formattedTime =
        "${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}";

    final bool canEditOrDelete =
        (_currentUserId == widget.senderId) || (_currentUserRole == "owner");

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<ImageProvider>(
              future: ProfileImageProvider.resolve(
                storagePath: profilePicturePath,
                fallbackUrl:
                    profilePictureUrl ?? AppConstants.defaultProfileImage,
              ),
              builder: (context, snapshot) {
                return CircleAvatar(
                  radius: 25.0,
                  backgroundImage: snapshot.data,
                );
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    senderName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.right,
                  ),
                  if (_isEditing)
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, color: Colors.green),
                          onPressed: _updateMessage,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        widget.message,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "🕒 $formattedTime ${messageTime.day}/${messageTime.month}/${messageTime.year}",
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.right,
                        ),
                        if (canEditOrDelete) ...[
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orange, size: 18),
                            onPressed: () => setState(() => _isEditing = true),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 18),
                            onPressed: _deleteMessage,
                          ),
                        ]
                      ],
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

  void _updateMessage() async {
    await _shiftService.updateMessage(
      widget.shiftId,
      widget.timestamp,
      _messageController.text,
    );
    setState(() => _isEditing = false);
  }

  void _deleteMessage() async {
    await _shiftService.deleteMessage(widget.shiftId, widget.timestamp);
  }
}
