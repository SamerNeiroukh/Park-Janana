import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../constants/app_constants.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final int timestamp;
  final String senderId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.senderId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseService().getUser(senderId), // Fetch sender details
      builder: (context, snapshot) {
        String senderName = "מנהל"; // Default
        String profileImage = AppConstants.defaultProfileImage; // Default

        if (snapshot.hasData && snapshot.data!.exists) {
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          senderName = userData['fullName'] ?? "מנהל";
          profileImage = (userData['profile_picture'] != null && userData['profile_picture'].isNotEmpty)
              ? userData['profile_picture']
              : AppConstants.defaultProfileImage;
        }

        DateTime messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        String formattedTime =
            "${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}";

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              CircleAvatar(
                radius: 30.0,
                backgroundImage: profileImage.startsWith('http')
                    ? NetworkImage(profileImage)
                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      senderName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "🕒 $formattedTime ${messageTime.day}/${messageTime.month}/${messageTime.year}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
