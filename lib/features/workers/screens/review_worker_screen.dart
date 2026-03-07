import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:park_janana/features/workers/screens/edit_worker_licenses_screen.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/workers/widgets/shifts_button.dart';
import 'package:park_janana/features/tasks/screens/create_task_flow_screen.dart';
import 'package:park_janana/features/reports/screens/worker_reports_screen.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class ReviewWorkerScreen extends StatelessWidget {
  final QueryDocumentSnapshot userData;
  /// Role of the currently logged-in manager ('manager' | 'owner')
  final String currentUserRole;

  const ReviewWorkerScreen({
    super.key,
    required this.userData,
    this.currentUserRole = 'manager',
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

    final String fullName = data['fullName'] ?? '';
    final String email = data['email'] ?? '';
    final String phone = data['phoneNumber'] ?? '';
    final String id = data['idNumber'] ?? '';
    final String uid = data['uid'] ?? '';
    final String role = data['role'] ?? '';

    // Managers cannot modify other managers — only owners can.
    final bool canManage =
        currentUserRole == 'owner' || role != 'manager';

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
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXL, vertical: AppDimensions.paddingXXL),
                child: Column(
                  children: [
                    _buildSpiritualProfile(data),
                    const SizedBox(height: AppDimensions.spacingXXXXL),
                    _buildSoftCard("🧾 פרטי העובד", [
                      _buildInfoRow(Icons.email_rounded, "אימייל", email),
                      _buildInfoRow(
                        Icons.phone,
                        "טלפון",
                        phone,
                        onTap: phone.isNotEmpty
                            ? () => launchUrl(Uri(scheme: 'tel', path: phone))
                            : null,
                      ),
                    ]),
                    const SizedBox(height: AppDimensions.spacingXXXL),
                    _buildSoftCard("🧭 פעולות מנהל", [
                      _buildActionCard(
                        icon: Icons.calendar_today_outlined,
                        label: "הצג משמרות",
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
                        icon: Icons.task_alt,
                        label: "שייך משימה",
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
                        icon: Icons.show_chart,
                        label: "הצג ביצועים",
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
                    ]),
                    const SizedBox(height: AppDimensions.spacingXXXL),
                    _buildSoftCard("🛠 ניהול משא", [
                      if (canManage) ...[
                        _buildFullWidthButton(
                          context,
                          label: "ניהול הרשאות ותפקיד",
                          icon: Icons.security_rounded,
                          color: AppColors.primary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditWorkerLicensesScreen(
                                  uid: uid,
                                  fullName: fullName,
                                  currentUserRole: currentUserRole,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.spacingL),
                        _buildFullWidthButton(
                          context,
                          label: "בטל אישור עובד",
                          icon: Icons.person_off_rounded,
                          color: AppColors.redLight,
                          onPressed: () => _unapproveWorker(context, uid),
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded,
                                  size: 16, color: Colors.grey.shade400),
                              const SizedBox(width: 8),
                              Text(
                                'אין הרשאה לניהול מנהלים אחרים',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualProfile(Map<String, dynamic> data) {
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
            imageUrl: data['profile_picture'],
            radius: AppDimensions.avatarM,
            backgroundColor: Colors.grey.shade300,
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
        const Text(
          "עובד בפארק ג׳ננה",
          style: TextStyle(color: Colors.grey, fontSize: AppDimensions.fontM),
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
            color: Colors.black12.withOpacity(0.05),
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
            const Icon(Icons.phone_forwarded_rounded,
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
          color: color.withOpacity(0.1),
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

  Future<void> _unapproveWorker(BuildContext context, String uid) async {
    final confirm = await showAppDialog(
      context,
      title: 'ביטול אישור עובד',
      message: 'העובד יועבר חזרה לרשימת הממתינים לאישור. הפעולה ניתנת לביטול.',
      confirmText: 'אשר',
      icon: Icons.person_remove_rounded,
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
          const SnackBar(content: Text("אישור העובד בוטל")),
        );
      }
    }
  }
}
