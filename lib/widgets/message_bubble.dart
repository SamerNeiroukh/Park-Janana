import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/shift_service.dart';
import '../constants/app_constants.dart';

class MessageBubble extends StatefulWidget {
  final String message;
  final int timestamp;
  final String senderId;
  final String shiftId;
  final bool canEdit;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.senderId,
    required this.shiftId,
    this.canEdit = false,
  });

  @override
  _MessageBubbleState createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final ShiftService _shiftService = ShiftService();
  bool _isEditing = false;
  TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.text = widget.message;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseService().getUser(widget.senderId),
      builder: (context, snapshot) {
        String senderName = "מנהל";
        String profileImage = AppConstants.defaultProfileImage;

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;
          senderName = userData['fullName'] ?? "מנהל";
          profileImage = (userData['profile_picture'] != null && userData['profile_picture'].isNotEmpty)
              ? userData['profile_picture']
              : AppConstants.defaultProfileImage;
        }

        DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(widget.timestamp);
        String formattedTime =
            "${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}";

        return Directionality(
          textDirection: TextDirection.rtl, // ✅ Everything starts from the right
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 25.0,
                  backgroundImage: profileImage.startsWith('http')
                      ? NetworkImage(profileImage)
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // ✅ Aligns text right after the picture
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                      if (_isEditing)
                        TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
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
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.right,
                            ),
                            if (widget.canEdit) ...[
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.orange, size: 18),
                                onPressed: () => setState(() => _isEditing = true),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
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
      },
    );
  }

  void _updateMessage() async {
    await _shiftService.updateMessage(widget.shiftId, widget.timestamp, _messageController.text);
    setState(() => _isEditing = false);
  }

  void _deleteMessage() async {
    await _shiftService.deleteMessage(widget.shiftId, widget.timestamp);
  }
}
