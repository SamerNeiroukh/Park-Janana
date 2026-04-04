import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ApproveWorkerScreen extends StatelessWidget {
  final QueryDocumentSnapshot userData;
  final String currentUserRole;

  const ApproveWorkerScreen({
    super.key,
    required this.userData,
    this.currentUserRole = 'manager',
  });

  Future<void> _approveWorker(BuildContext context, AppLocalizations l10n) async {
    final String uid = userData['uid'];
    await FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(uid).update({
      'approved': true,
    });

    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.workerApproved)),
    );
  }

  Future<void> _rejectWorker(BuildContext context, AppLocalizations l10n) async {
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
      SnackBar(content: Text(l10n.applicationRejectedSnackbar)),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required AppLocalizations l10n,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showAppDialog(
      context,
      title: title,
      message: content,
      confirmText: l10n.confirmButton,
      icon: PhosphorIconsRegular.checkCircle,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    ).then((confirmed) {
      if (confirmed ?? false) onConfirm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    l10n,
                  ),
                  const SizedBox(height: AppDimensions.spacingXXXL),
                  _buildInfoCard(l10n.workerDetailsCardTitle, [
                    _buildInfoRow(l10n.approveEmailLabel, email),
                    _buildInfoRow(l10n.workerPhoneInfoLabel, phone),
                  ]),
                  const SizedBox(height: AppDimensions.spacingXXXXL),
                  _buildActionButtons(context, l10n),
                  const SizedBox(height: AppDimensions.spacingXXXXL),
                ],
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
    AppLocalizations l10n,
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
        Text(
          l10n.newWorkerPendingApproval,
          style: const TextStyle(fontSize: AppDimensions.fontM, color: Colors.grey),
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
            color: Colors.black12.withValues(alpha: 0.05),
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

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        _buildFullWidthButton(
          context,
          label: l10n.approveWorkerButton,
          icon: PhosphorIconsRegular.checkCircle,
          color: AppColors.success,
          onPressed: () => _showConfirmationDialog(
            context: context,
            l10n: l10n,
            title: l10n.approveWorkerTitle,
            content: l10n.approveConfirmContent,
            onConfirm: () => _approveWorker(context, l10n),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _buildFullWidthButton(
          context,
          label: l10n.rejectApplicationButton,
          icon: PhosphorIconsRegular.xCircle,
          color: AppColors.error,
          onPressed: () => _showConfirmationDialog(
            context: context,
            l10n: l10n,
            title: l10n.rejectApplicationTitle,
            content: l10n.rejectConfirmContent,
            onConfirm: () => _rejectWorker(context, l10n),
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
