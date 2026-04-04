import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:park_janana/features/workers/screens/edit_worker_licenses_screen.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/workers/widgets/shifts_button.dart';
import 'package:park_janana/features/tasks/screens/create_task_flow_screen.dart';
import 'package:park_janana/features/reports/screens/worker_reports_screen.dart';
import 'package:park_janana/features/attendance/screens/attendance_correction_screen.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ReviewWorkerScreen extends StatelessWidget {
  final QueryDocumentSnapshot userData;
  /// Role of the currently logged-in user ('manager' | 'co_owner' | 'owner')
  final String currentUserRole;
  /// UID of the currently logged-in user (used to prevent self-demotion)
  final String currentUserId;

  const ReviewWorkerScreen({
    super.key,
    required this.userData,
    this.currentUserRole = 'manager',
    this.currentUserId = '',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

    final String fullName = data['fullName'] ?? '';
    final String email = data['email'] ?? '';
    final String phone = data['phoneNumber'] ?? '';
    final String id = data['idNumber'] ?? '';
    final String uid = data['uid'] ?? '';
    final String role = data['role'] ?? '';

    // Role hierarchy:
    // - Owner can manage anyone.
    // - Co-owner can manage managers and workers only (not owner, not other co-owners).
    // - Manager can manage certificates for workers only (not roles, not unapproval).
    final bool canManageRole = currentUserRole == 'owner' ||
        (currentUserRole == 'co_owner' &&
            role != 'owner' &&
            role != 'co_owner');

    final bool canManageCertificates = canManageRole ||
        (currentUserRole == 'manager' && role == 'worker');

    final worker = UserModel(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phone,
      idNumber: id,
      profilePicture: data['profile_picture'] ?? '',
      profilePicturePath: data['profile_picture_path'],
      role: role,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundCard,
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL, vertical: AppDimensions.paddingXXL),
              child: Column(
                children: [
                  _buildSpiritualProfile(context, data, l10n),
                  const SizedBox(height: AppDimensions.spacingXXXXL),
                  _buildSoftCard(l10n.workerDetailsCardTitle, [
                    _buildInfoRow(PhosphorIconsRegular.envelope, l10n.workerEmailInfoLabel, email),
                    _buildInfoRow(
                      PhosphorIconsRegular.phone,
                      l10n.workerPhoneInfoLabel,
                      phone,
                      onTap: phone.isNotEmpty
                          ? () => launchUrl(Uri(scheme: 'tel', path: phone))
                          : null,
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.spacingXXXL),
                  _buildSoftCard(l10n.adminActionsCardTitle, [
                    _buildActionCard(
                      icon: PhosphorIconsRegular.calendarBlank,
                      label: l10n.showShiftsButton,
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShiftsButtonScreen(
                              uid: uid,
                              fullName: fullName,
                              profilePicture: data['profile_picture'] ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: PhosphorIconsRegular.checkSquare,
                      label: l10n.assignTaskButton,
                      color: Colors.indigo,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateTaskFlowScreen(
                              initialSelectedUsers: [worker],
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: PhosphorIconsRegular.trendUp,
                      label: l10n.viewPerformanceButton,
                      color: AppColors.deepOrange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkerReportsScreen(
                            userId: uid,
                            userName: fullName,
                            profileUrl: data['profile_picture'] ?? '',
                          ),
                        ),
                      ),
                    ),
                    _buildActionCard(
                      icon: PhosphorIconsRegular.calendarPlus,
                      label: l10n.correctAttendanceButton,
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AttendanceCorrectionScreen(
                            userId: uid,
                            userName: fullName,
                          ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppDimensions.spacingXXXL),
                  _buildSoftCard(l10n.manageLicensesCardTitle, [
                    if (canManageCertificates) ...[
                      _buildFullWidthButton(
                        context,
                        label: l10n.managePermissionsButton,
                        icon: PhosphorIconsRegular.shield,
                        color: AppColors.primary,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditWorkerLicensesScreen(
                                uid: uid,
                                fullName: fullName,
                                currentUserRole: currentUserRole,
                                currentUserId: currentUserId,
                              ),
                            ),
                          );
                        },
                      ),
                      if (canManageRole) ...[
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildFullWidthButton(
                          context,
                          label: l10n.revokeApprovalButton,
                          icon: PhosphorIconsRegular.userMinus,
                          color: AppColors.redLight,
                          onPressed: () => _unapproveWorker(context, uid, l10n),
                        ),
                      ],
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(PhosphorIconsRegular.lock,
                                size: 16, color: Colors.grey.shade400),
                            const SizedBox(width: 8),
                            Text(
                              l10n.noPermissionForUser,
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ]),
                  const SizedBox(height: AppDimensions.spacingHuge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualProfile(BuildContext context, Map<String, dynamic> data, AppLocalizations l10n) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => ProfileAvatar.showFullScreen(
              context, data['profile_picture'] as String?),
          child: Container(
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
              imageUrl: data['profile_picture'],
              radius: AppDimensions.avatarM,
              backgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXL),
        Text(
          data['fullName'] ?? '',
          style: const TextStyle(
            fontSize: AppDimensions.fontTitle,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Text(
          l10n.workerSubtitleInPark,
          style: const TextStyle(color: Colors.grey, fontSize: AppDimensions.fontM),
        ),
      ],
    );
  }

  Widget _buildSoftCard(String title, List<Widget> children) {
    return Container(
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
      padding: AppDimensions.paddingSymmetricCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppDimensions.fontXL,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: AppDimensions.spacingML),
          const Divider(),
          const SizedBox(height: AppDimensions.spacingS),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.paddingS),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: AppDimensions.spacingL),
          Text("$label:",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: AppDimensions.fontML)),
          const SizedBox(width: AppDimensions.spacingM),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: AppDimensions.fontML,
                  color: onTap != null ? AppColors.primary : null,
                  decoration:
                      onTap != null ? TextDecoration.underline : null,
                ),
                overflow: TextOverflow.ellipsis),
          ),
          if (onTap != null)
            const Icon(PhosphorIconsRegular.phoneOutgoing,
                size: 16, color: AppColors.accent),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: row,
      );
    }
    return IgnorePointer(child: row);
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: AppDimensions.spacingL),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL, vertical: AppDimensions.paddingML),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppDimensions.borderRadiusXL,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: AppDimensions.iconML),
            const SizedBox(width: AppDimensions.spacingL),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: AppDimensions.fontL,
              ),
            ),
          ],
        ),
      ),
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
                fontWeight: FontWeight.bold, fontSize: AppDimensions.fontL, color: AppColors.textWhite),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: AppDimensions.elevationM,
          shape:
              RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusML),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Future<void> _unapproveWorker(BuildContext context, String uid, AppLocalizations l10n) async {
    final confirm = await showAppDialog(
      context,
      title: l10n.revokeApprovalTitle,
      message: l10n.revokeApprovalMessage,
      confirmText: l10n.confirmButton,
      icon: PhosphorIconsRegular.userMinus,
      iconGradient: const [Color(0xFFFF8C00), Color(0xFFE65100)],
    );

    if (confirm ?? false) {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'approved': false});
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.approvalRevoked)),
        );
      }
    }
  }
}
