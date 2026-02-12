import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/core/config/departments.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class PersonalAreaScreen extends StatefulWidget {
  final String uid;

  const PersonalAreaScreen({required this.uid, super.key});

  @override
  _PersonalAreaScreenState createState() => _PersonalAreaScreenState();
}

class _PersonalAreaScreenState extends State<PersonalAreaScreen> {
  File? _imageFile;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Load user data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().getUserById(widget.uid);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isUploading) return;

    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'חתוך תמונה',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'חתוך תמונה',
            aspectRatioLockEnabled: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _imageFile = File(croppedFile.path);
        });
        _confirmUpload();
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null && !_isUploading) {
      setState(() => _isUploading = true);
      try {
        // Evict old cached image so the new one loads fresh
        final oldUrl = context.read<UserProvider>().currentUser?.profilePicture;
        if (oldUrl != null) {
          await ProfileImageProvider.evict(oldUrl);
        }

        final storageRef =
            _storage.ref().child('profile_pictures/${widget.uid}/profile.jpg');

        await storageRef.putFile(_imageFile!);
        final downloadUrl = await storageRef.getDownloadURL();

        // Update Firestore with both the storage path and the fresh download URL
        await _firestore.collection(AppConstants.usersCollection).doc(widget.uid).update({
          'profile_picture_path': storageRef.fullPath,
          'profile_picture': downloadUrl,
        });

        // Refresh user data in provider so all screens update instantly
        if (mounted) {
          await context.read<UserProvider>().refresh();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "תמונת הפרופיל עודכנה בהצלחה.",
                style: AppTheme.bodyText,
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("שגיאה בהעלאת תמונה: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  void _showOptions() {
    if (_isUploading) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black),
                title: const Text("צלם תמונה"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.black),
                title: const Text("העלה תמונה"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmUpload() {
    if (_isUploading) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("האם להגדיר כתמונת פרופיל?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _uploadImage();
              },
              child: const Text("כן"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("לא"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Builder(
              builder: (context) {
                // Check if we're currently loading this specific user
                if (userProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Try to get user from cache
                UserModel? userData;
                if (userProvider.currentUser?.uid == widget.uid) {
                  userData = userProvider.currentUser;
                } else {
                  // For other users, we'd need to fetch from cache
                  // For now, show loading if not available
                  return FutureBuilder<UserModel?>(
                    future:
                        context.read<UserProvider>().getUserById(widget.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return const Center(
                            child: Text("שגיאה בטעינת הפרופיל."));
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Center(
                            child: Text("לא נמצאו נתונים להצגה."));
                      }
                      userData = snapshot.data;
                      return _buildProfileContent(userData!);
                    },
                  );
                }

                if (userData == null) {
                  return const Center(child: Text("לא נמצאו נתונים להצגה."));
                }

                return _buildProfileContent(userData);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(UserModel userData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 85,
                backgroundColor: AppColors.accent,
                child: ProfileAvatar(
                  imageUrl: userData.profilePicture,
                  radius: 80,
                ),
              ),
              Positioned(
                right: 5,
                bottom: 5,
                child: GestureDetector(
                  onTap: _showOptions,
                  child: const CircleAvatar(
                    backgroundColor: AppColors.background,
                    radius: 22,
                    child: Icon(Icons.camera_alt, color: Colors.blue, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _buildInfoCard([
            _buildInfoRow(Icons.person, "שם מלא", userData.fullName),
            _buildInfoRow(Icons.email, "אימייל", userData.email),
            _buildInfoRow(Icons.badge, "תעודת זהות", userData.idNumber),
            _buildInfoRow(Icons.phone, "מספר טלפון", userData.phoneNumber),
          ]),
          const SizedBox(height: 20),
          _buildLicensesSection(userData),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusXL),
      elevation: AppDimensions.elevationL,
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String field, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.blueGrey.shade700),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(field,
                    style: AppTheme.sectionTitle
                        .copyWith(color: AppColors.accent)),
                Text(value, style: AppTheme.bodyText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicensesSection(UserModel userData) {
    final List<String> licensed = userData.licensedDepartments;
    const List<String> departments = allDepartments;

    final Map<String, IconData> departmentIcons = {
      "פארק חבלים": Icons.hiking,
      "פיינטבול": Icons.sports_esports,
      "קרטינג": Icons.sports_score,
      "פארק מים": Icons.pool,
      "ג'ימבורי": Icons.sports_gymnastics,
      "תפעול": Icons.handyman,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusXL),
      elevation: AppDimensions.elevationL,
      color: AppColors.background,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text("הרשאות עבודה לפי מחלקה", style: AppTheme.sectionTitle),
            const SizedBox(height: 10),
            ...departments.map((dept) {
              final bool isLicensed = licensed.contains(dept);
              final IconData icon = departmentIcons[dept] ?? Icons.help_outline;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                decoration: BoxDecoration(
                  color: isLicensed
                      ? AppColors.lightGreen.withOpacity(0.15)
                      : Colors.grey.shade100,
                  borderRadius: AppDimensions.borderRadiusL,
                  border: Border.all(
                    color:
                        isLicensed ? AppColors.success : Colors.grey.shade300,
                    width: 1.0,
                  ),
                ),
                child: ListTile(
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dept,
                        style: AppTheme.bodyText
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8.0),
                      Icon(icon, color: AppColors.accent, size: 26),
                    ],
                  ),
                  leading: Icon(
                    isLicensed ? Icons.lock_open : Icons.lock_outline,
                    color: isLicensed ? AppColors.success : Colors.redAccent,
                    size: 26,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
