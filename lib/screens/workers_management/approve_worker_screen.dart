import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/utils/profile_image_provider.dart';

class ApproveWorkerScreen extends StatelessWidget {
  final QueryDocumentSnapshot userData;

  const ApproveWorkerScreen({super.key, required this.userData});

  Future<void> _approveWorker(BuildContext context) async {
    final String uid = userData['uid'];
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'approved': true,
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('העובד אושר בהצלחה')),
    );
  }

  Future<void> _rejectWorker(BuildContext context) async {
    final String uid = userData['uid'];
    await FirebaseFirestore.instance.collection('users').doc(uid).delete();

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('העובד נמחק מהמערכת')),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title, textDirection: TextDirection.rtl),
        content: Text(content, textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ביטול"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text("אישור"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = userData.data() as Map<String, dynamic>;

    final String fullName = data['fullName'] ?? '';
    final String email = data['email'] ?? '';
    final String phone = data['phoneNumber'] ?? '';
    final String id = data['idNumber'] ?? '';
    final String fallbackPicture = data['profile_picture'] ?? '';

    // ✅ SAFE access (this is the fix)
    final String? profilePicturePath = data.containsKey('profile_picture_path')
        ? data['profile_picture_path']
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileHeader(
                      profilePicturePath,
                      fallbackPicture,
                      fullName,
                    ),
                    const SizedBox(height: 24),
                    _buildInfoCard("🧾 פרטי העובד", [
                      _buildInfoRow("דוא\"ל", email),
                      _buildInfoRow("טלפון", phone),
                      _buildInfoRow("ת.ז", id),
                    ]),
                    const SizedBox(height: 30),
                    _buildActionButtons(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(
    String? storagePath,
    String fallbackUrl,
    String name,
  ) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FutureBuilder<ImageProvider>(
            future: ProfileImageProvider.resolve(
              storagePath: storagePath,
              fallbackUrl: fallbackUrl,
            ),
            builder: (context, snapshot) {
              return CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: snapshot.data,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        const Text(
          "עובד חדש ממתין לאישור",
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildFullWidthButton(
          context,
          label: "אשר עובד",
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onPressed: () => _showConfirmationDialog(
            context: context,
            title: "אישור עובד",
            content: "האם אתה בטוח שברצונך לאשר את העובד הזה?",
            onConfirm: () => _approveWorker(context),
          ),
        ),
        const SizedBox(height: 12),
        _buildFullWidthButton(
          context,
          label: "דחה ומחק",
          icon: Icons.cancel_outlined,
          color: Colors.red,
          onPressed: () => _showConfirmationDialog(
            context: context,
            title: "דחיית עובד",
            content: "האם אתה בטוח שברצונך לדחות ולמחוק את העובד הזה?",
            onConfirm: () => _rejectWorker(context),
          ),
        ),
      ],
    );
  }

  Widget _buildFullWidthButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
