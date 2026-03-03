import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class ApproveWorkerScreen extends StatelessWidget {
  final QueryDocumentSnapshot userData;
  final String currentUserRole;

  const ApproveWorkerScreen({
    super.key,
    required this.userData,
    this.currentUserRole = 'manager',
  });

  Future<void> _approveWorker(BuildContext context) async {
    final String uid = userData['uid'];
    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(uid).update({
      'approved': true,
    });

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('העובד אושר בהצלחה')),
    );
  }

  Future<void> _rejectWorker(BuildContext context) async {
    final String uid = userData['uid'];
    // Write rejectedAt (triggers Cloud Function notification) + rejected:true
    // so the pending workers query can filter this user out client-side.
    await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejected': true,
    });

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('הבקשה נדחתה. העובד קיבל הודעה.')),
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
    final String profilePictureUrl = data['profile_picture'] ?? '';

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
                      profilePictureUrl,
                      fullName,
                    ),
                    const SizedBox(height: AppDimensions.spacingXXXL),
                    _buildInfoCard("🧾 פרטי העובד", [
                      _buildInfoRow("דוא\"ל", email),
                      _buildInfoRow("טלפון", phone),
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
    String imageUrl,
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
          child: ProfileAvatar(
            imageUrl: imageUrl,
            radius: AppDimensions.avatarM,
            backgroundColor: Colors.grey.shade300,
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
    return IgnorePointer(
      child: Padding(
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
          label: "דחה בקשה",
          icon: Icons.cancel_outlined,
          color: AppColors.error,
          onPressed: () => _showConfirmationDialog(
            context: context,
            title: "דחיית בקשה",
            content: "העובד ישאר בהמתנה ויוכל להגיש בקשה שוב. האם לדחות?",
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
