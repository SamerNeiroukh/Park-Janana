import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';

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
      backgroundColor: AppColors.backgroundCard,
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingXL,
                    vertical: AppDimensions.paddingXXL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildProfileHeader(
                      profilePicturePath,
                      fallbackPicture,
                      fullName,
                    ),
                    const SizedBox(height: AppDimensions.spacingXXXL),
                    _buildInfoCard("🧾 פרטי העובד", [
                      _buildInfoRow("דוא\"ל", email),
                      _buildInfoRow("טלפון", phone),
                      _buildInfoRow("ת.ז", id),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXXXXL),
                    _buildActionButtons(context),
                    const SizedBox(height: AppDimensions.spacingXXXXL),
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
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: AppDimensions.shadowBlurS,
                offset: AppDimensions.shadowOffsetS,
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
                radius: AppDimensions.avatarM,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: snapshot.data,
              );
            },
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXL),
        Text(
          name,
          style: const TextStyle(
              fontSize: AppDimensions.fontTitle,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        const Text(
          "עובד חדש ממתין לאישור",
          style: TextStyle(fontSize: AppDimensions.fontM, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: AppDimensions.paddingSymmetricCard,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.borderRadiusXXL,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: AppDimensions.shadowBlurM,
            offset: AppDimensions.shadowOffsetM,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: AppDimensions.fontXL, fontWeight: FontWeight.w600)),
          const SizedBox(height: AppDimensions.spacingL),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: AppDimensions.fontML),
          ),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: AppDimensions.fontML),
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
          color: AppColors.success,
          onPressed: () => _showConfirmationDialog(
            context: context,
            title: "אישור עובד",
            content: "האם אתה בטוח שברצונך לאשר את העובד הזה?",
            onConfirm: () => _approveWorker(context),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildFullWidthButton(
          context,
          label: "דחה ומחק",
          icon: Icons.cancel_outlined,
          color: AppColors.error,
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
        icon: Icon(icon, color: AppColors.textWhite),
        label: Padding(
          padding: AppDimensions.paddingSymmetricButton,
          child: Text(
            label,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: AppDimensions.fontL,
                color: AppColors.textWhite),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: AppDimensions.elevationM,
          shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusML),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
