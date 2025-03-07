import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_janana/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/user_header.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';

class PersonalAreaScreen extends StatefulWidget {
  final String uid;

  const PersonalAreaScreen({required this.uid, super.key});

  @override
  _PersonalAreaScreenState createState() => _PersonalAreaScreenState();
}

class _PersonalAreaScreenState extends State<PersonalAreaScreen> {
  File? _imageFile;
  final AuthService _authService = AuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Cache for user profile data
  static final Map<String, Map<String, dynamic>> _userCache = {};

  // ✅ Set a valid default profile picture
  static const String defaultProfilePictureUrl =
      "https://firebasestorage.googleapis.com/v0/b/park-janana-app.appspot.com/o/profile_pictures%2Fdefault_profile.png?alt=media";

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _confirmUpload();
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      try {
        final storageRef =
            _storage.ref().child('profile_pictures/${widget.uid}/profile.jpg');
        await storageRef.putFile(_imageFile!);
        final downloadUrl = await storageRef.getDownloadURL();
        await _authService.updateProfilePicture(widget.uid, downloadUrl);

        // ✅ Update cache to reflect changes
        _userCache[widget.uid]?['profile_picture'] = downloadUrl;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("תמונת הפרופיל עודכנה בהצלחה.", style: AppTheme.bodyText),
              backgroundColor: AppColors.success,
            ),
          );
          setState(() {}); // Refresh UI
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("שגיאה בהעלאת תמונה: $e")),
          );
        }
      }
    }
  }

  void _showOptions() {
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
                title: const Text("צלם תמונה", style: TextStyle(color: Colors.black)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.black),
                title: const Text("העלה תמונה", style: TextStyle(color: Colors.black)),
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

  Future<Map<String, dynamic>> _fetchUserData() async {
    // ✅ Use cached data if available
    if (_userCache.containsKey(widget.uid)) {
      return Future.value(_userCache[widget.uid]!);
    }

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // ✅ Store fetched data in cache
        _userCache[widget.uid] = userData;
        return userData;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }

    return {}; // Return empty if failed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchUserData(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("שגיאה בטעינת הפרופיל.");
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("לא נמצאו נתונים להצגה.");
                }

                final userData = snapshot.data!;
                String profilePicture = userData['profile_picture'] ?? '';

                if (profilePicture.isEmpty || !profilePicture.startsWith('http')) {
                  profilePicture = defaultProfilePictureUrl;
                }

                final fullName = userData['fullName'] ?? 'לא ידוע';
                final email = userData['email'] ?? 'לא ידוע';
                final idNumber = userData['idNumber'] ?? 'לא ידוע';
                final phoneNumber = userData['phoneNumber'] ?? 'לא ידוע';

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
                            child: CircleAvatar(
                              radius: 80,
                              backgroundImage: NetworkImage(profilePicture),
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
                        _buildInfoRow(Icons.person, "שם מלא", fullName),
                        _buildInfoRow(Icons.email, "אימייל", email),
                        _buildInfoRow(Icons.badge, "תעודת זהות", idNumber),
                        _buildInfoRow(Icons.phone, "מספר טלפון", phoneNumber),
                      ]),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 4,
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
                Text(field, style: AppTheme.sectionTitle.copyWith(color: AppColors.accent)),
                Text(value, style: AppTheme.bodyText),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
