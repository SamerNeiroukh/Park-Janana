import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/screens/workers_management/edit_worker_licenses_screen.dart';
import 'package:park_janana/widgets/user_header.dart';

class ReviewWorkerScreen extends StatelessWidget {
  final QueryDocumentSnapshot userData;

  const ReviewWorkerScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final String fullName = userData['fullName'] ?? '';
    final String email = userData['email'] ?? '';
    final String phone = userData['phoneNumber'] ?? '';
    final String id = userData['idNumber'] ?? '';
    final String profilePicture = userData['profile_picture'] ?? '';
    final String uid = userData['uid'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _buildSpiritualProfile(profilePicture, fullName),
                    const SizedBox(height: 30),
                    _buildSoftCard("🧾 פרטי העובד", [
                      _buildInfoRow(Icons.email_rounded, "אימייל", email),
                      _buildInfoRow(Icons.phone, "טלפון", phone),
                      _buildInfoRow(Icons.credit_card, "תעודת זהות", id),
                    ]),
                    const SizedBox(height: 24),
                    _buildSoftCard("🧭 פעולות מנהל", [
                      _buildActionCard(
                        icon: Icons.calendar_today_outlined,
                        label: "הצג משמרות",
                        color: Colors.teal,
                        onTap: () => _snack(context, "הצגת משמרות - בפיתוח"),
                      ),
                      _buildActionCard(
                        icon: Icons.task_alt,
                        label: "שייך משימה",
                        color: Colors.indigo,
                        onTap: () => _snack(context, "שייך משימה - בפיתוח"),
                      ),
                      _buildActionCard(
                        icon: Icons.show_chart,
                        label: "הצג ביצועים",
                        color: Colors.deepOrange,
                        onTap: () => _snack(context, "הצגת ביצועים - בפיתוח"),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSoftCard("🛠 ניהול משא", [
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
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildFullWidthButton(
                        context,
                        label: "מחק עובד",
                        icon: Icons.delete_forever,
                        color: Colors.red.shade600,
                        onPressed: () => _deleteWorker(context, uid),
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpiritualProfile(String image, String name) {
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
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: image.isNotEmpty
                ? NetworkImage(image)
                : const AssetImage('assets/images/default_profile.png') as ImageProvider,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "עובד בפארק ג׳ננה",
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSoftCard(String title, List<Widget> children) {
    return Container(
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
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 17,
                color: Colors.black87,
              )),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Text("$label:",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
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
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 16,
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
        icon: Icon(icon, color: Colors.white),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onPressed,
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _deleteWorker(BuildContext context, String uid) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("מחיקת עובד"),
        content: const Text("האם אתה בטוח שברצונך למחוק את העובד הזה?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("ביטול")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("מחק", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm) {
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("העובד נמחק בהצלחה")),
        );
      }
    }
  }
}
