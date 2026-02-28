import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/core/config/departments.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF4F46E5);
const _kViolet = Color(0xFF7C3AED);
const _kBg = Color(0xFFF0F2FC);

const _kCardShadow = [
  BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 4)),
  BoxShadow(color: Color(0x07000000), blurRadius: 6, offset: Offset(0, 1)),
];

// ─────────────────────────────────────────────────────────────────────────────

class PersonalAreaScreen extends StatefulWidget {
  final String uid;
  const PersonalAreaScreen({required this.uid, super.key});

  @override
  State<PersonalAreaScreen> createState() => _PersonalAreaScreenState();
}

class _PersonalAreaScreenState extends State<PersonalAreaScreen> {
  File? _imageFile;
  final _storage = FirebaseStorage.instance;
  final _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().getUserById(widget.uid);
    });
  }

  // ── Image picking & upload ─────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'חתוך תמונה',
          toolbarColor: _kPrimary,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: true,
        ),
        IOSUiSettings(title: 'חתוך תמונה', aspectRatioLockEnabled: true),
      ],
    );

    if (croppedFile != null) {
      setState(() => _imageFile = File(croppedFile.path));
      _confirmUpload();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null || _isUploading) return;
    setState(() => _isUploading = true);
    try {
      final oldUrl = context.read<UserProvider>().currentUser?.profilePicture;
      if (oldUrl != null) await ProfileImageProvider.evict(oldUrl);

      final storageRef =
          _storage.ref().child('profile_pictures/${widget.uid}/profile.jpg');
      await storageRef.putFile(_imageFile!);
      final downloadUrl = await storageRef.getDownloadURL();

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(widget.uid)
          .update({
        'profile_picture_path': storageRef.fullPath,
        'profile_picture': downloadUrl,
      });

      if (mounted) await context.read<UserProvider>().refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('תמונת הפרופיל עודכנה בהצלחה'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('שגיאה: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showImageOptions() {
    if (_isUploading) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'עדכון תמונת פרופיל',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'בחר מקור לתמונה',
                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 20),
              _OptionTile(
                icon: Icons.camera_alt_rounded,
                label: 'צלם תמונה',
                subtitle: 'השתמש במצלמה',
                color: _kPrimary,
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 10),
              _OptionTile(
                icon: Icons.photo_library_rounded,
                label: 'בחר מהגלריה',
                subtitle: 'העלה מהתמונות שלך',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmUpload() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('עדכון תמונת פרופיל'),
          content: const Text('להגדיר תמונה זו כתמונת הפרופיל שלך?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ביטול'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: () {
                Navigator.pop(ctx);
                _uploadImage();
              },
              child: const Text('אישור'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kBg,
        body: Builder(builder: (context) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          UserModel? userData;
          if (userProvider.currentUser?.uid == widget.uid) {
            userData = userProvider.currentUser;
          }

          if (userData == null) {
            return FutureBuilder<UserModel?>(
              future: context.read<UserProvider>().getUserById(widget.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data == null) {
                  return const Center(child: Text('לא נמצאו נתונים'));
                }
                return _buildContent(snapshot.data!);
              },
            );
          }
          return _buildContent(userData);
        }),
      ),
    );
  }

  Widget _buildContent(UserModel user) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(user)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 12), // avatar clearance (header now 58px taller)
              _buildNameSection(user),
              const SizedBox(height: 20),
              _buildStatsRow(user),
              const SizedBox(height: 16),
              _buildInfoCard(user),
              const SizedBox(height: 16),
              _buildDepartmentsCard(user),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(UserModel user) {
    final topPad = MediaQuery.of(context).padding.top;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient background
        Container(
          height: 190 + topPad,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4338CA), _kViolet],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
        // Decorative blobs
        Positioned(top: -50, left: -50, child: _blob(180, 0.08)),
        Positioned(bottom: 58, right: -50, child: _blob(150, 0.06)),
        Positioned(top: topPad + 50, right: 40, child: _blob(55, 0.07)),
        Positioned(top: topPad + 20, left: 80, child: _blob(35, 0.06)),
        // Back button (RTL: left side, pointing right)
        Positioned(
          top: topPad + 8,
          left: 8,
          child: IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        // Screen title
        Positioned(
          top: topPad + 14,
          left: 0,
          right: 0,
          child: const Center(
            child: Text(
              'הפרופיל שלי',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        // Avatar at the bottom edge
        // bottom: 0 keeps the same visual position as the old bottom: -58
        // but the Stack is 58 px taller so the hit-test area covers the
        // camera button which was previously outside the Stack bounds.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(child: _buildAvatar(user)),
        ),
        SizedBox(height: 248 + topPad),
      ],
    );
  }

  Widget _blob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(opacity),
        ),
      );

  Widget _buildAvatar(UserModel user) {
    // Wrap entire avatar (photo + camera button) in one GestureDetector so
    // tapping the photo OR the camera icon both open the image picker.
    return GestureDetector(
      onTap: _showImageOptions,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          // Gradient ring + white buffer + photo
          Container(
            width: 122,
            height: 122,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), _kViolet],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            // White buffer ring so the gradient ring is more visible
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(
                child: _isUploading
                    ? const SizedBox(
                        width: 110,
                        height: 110,
                        child: Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                                strokeWidth: 3, color: _kPrimary),
                          ),
                        ),
                      )
                    : ProfileAvatar(imageUrl: user.profilePicture, radius: 56),
              ),
            ),
          ),
          // Camera edit button (visual; tap is handled by parent GestureDetector)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF818CF8), _kPrimary],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }

  // ── Name + Role section ────────────────────────────────────────────────────

  Widget _buildNameSection(UserModel user) {
    final role = _roleInfo(user.role);
    return Column(
      children: [
        Text(
          user.fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [role.color, role.color.withOpacity(0.75)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: role.color.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(role.icon, color: Colors.white, size: 14),
              const SizedBox(width: 7),
              Text(
                role.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────

  Widget _buildStatsRow(UserModel user) {
    final licensed = user.licensedDepartments.length;
    final total = allDepartments.length;
    final pct = total == 0 ? 0 : ((licensed / total) * 100).round();
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.verified_rounded,
            value: '$licensed / $total',
            label: 'מחלקות מורשות',
            color: _kPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.shield_outlined,
            value: '$pct%',
            label: 'כיסוי הרשאות',
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  // ── Info card ──────────────────────────────────────────────────────────────

  Widget _buildInfoCard(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        children: [
          _cardHeader(
            icon: Icons.person_outline_rounded,
            color: _kPrimary,
            title: 'פרטים אישיים',
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          _InfoRow(
            icon: Icons.email_outlined,
            iconColor: _kPrimary,
            label: 'אימייל',
            value: user.email,
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            iconColor: const Color(0xFF0EA5E9),
            label: 'תעודת זהות',
            value: user.idNumber,
          ),
          _InfoRow(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF10B981),
            label: 'מספר טלפון',
            value: user.phoneNumber,
            isLast: true,
          ),
        ],
      ),
    );
  }

  // ── Departments card ───────────────────────────────────────────────────────

  Widget _buildDepartmentsCard(UserModel user) {
    final licensed = user.licensedDepartments;
    final ratio =
        allDepartments.isEmpty ? 0.0 : licensed.length / allDepartments.length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _kCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            icon: Icons.verified_user_rounded,
            color: _kPrimary,
            title: 'הרשאות מחלקה',
            trailing: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${licensed.length}/${allDepartments.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_kPrimary),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  licensed.isEmpty
                      ? 'אין הרשאות פעילות'
                      : '${(ratio * 100).round()}% מהמחלקות פעילות',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: allDepartments.map((dept) {
                return _DeptChip(
                  label: dept,
                  icon: getDepartmentIcon(dept),
                  color: getDepartmentColor(dept),
                  licensed: licensed.contains(dept),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared card header ─────────────────────────────────────────────────────

  Widget _cardHeader({
    required IconData icon,
    required Color color,
    required String title,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  // ── Role helper ────────────────────────────────────────────────────────────

  _RoleInfo _roleInfo(String role) {
    switch (role) {
      case 'worker':
        return _RoleInfo(
          label: 'עובד',
          icon: Icons.engineering_rounded,
          color: _kPrimary,
        );
      case 'manager':
        return _RoleInfo(
          label: 'מנהל',
          icon: Icons.manage_accounts_rounded,
          color: const Color(0xFF059669),
        );
      default:
        return _RoleInfo(
          label: 'בעלים',
          icon: Icons.business_center_rounded,
          color: const Color(0xFFD97706),
        );
    }
  }
}

// ── Simple data container ────────────────────────────────────────────────────

class _RoleInfo {
  final String label;
  final IconData icon;
  final Color color;
  _RoleInfo({required this.label, required this.icon, required this.color});
}

// ─────────────────────────────────────────────────────────────────────────────
// Private sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _kCardShadow,
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
            height: 1,
            indent: 72,
            endIndent: 20,
            color: Color(0xFFF3F4F6),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DeptChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool licensed;

  const _DeptChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.licensed,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        licensed ? color : const Color(0xFFCBD5E1);
    final bg = licensed
        ? color.withOpacity(0.09)
        : const Color(0xFFF8FAFC);
    final border = licensed
        ? color.withOpacity(0.28)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            licensed
                ? Icons.check_circle_rounded
                : Icons.lock_outline_rounded,
            size: 13,
            color: effectiveColor,
          ),
          const SizedBox(width: 5),
          Icon(icon, size: 13, color: effectiveColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: licensed ? color : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withOpacity(0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
