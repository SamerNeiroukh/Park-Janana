import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_janana/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/user_header.dart';

class PersonalAreaScreen extends StatefulWidget {
  final String uid;

  const PersonalAreaScreen({required this.uid, super.key});

  @override
  _PersonalAreaScreenState createState() => _PersonalAreaScreenState();
}

class _PersonalAreaScreenState extends State<PersonalAreaScreen> {
  File? _imageFile;
  bool _isUploading = false;
  final AuthService _authService = AuthService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      setState(() {
        _isUploading = true;
      });
      try {
        final storageRef = _storage.ref().child('profile_pictures/${widget.uid}.jpg');
        await storageRef.putFile(_imageFile!);
        final downloadUrl = await storageRef.getDownloadURL();
        await _authService.updateProfilePicture(widget.uid, downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("תמונת הפרופיל עודכנה בהצלחה.")),
        );
        Navigator.pop(context, downloadUrl);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("שגיאה בהעלאת תמונה: $e")),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(), // ✅ Keep consistency with HomeScreen
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('users').doc(widget.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("שגיאה בטעינת הפרופיל.");
                }

                if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final userDoc = snapshot.data!;
                final profilePicture = userDoc['profile_picture'] ?? '';
                final fullName = userDoc['fullName'] ?? 'לא ידוע';
                final email = userDoc['email'] ?? 'לא ידוע';
                final idNumber = userDoc['idNumber'] ?? 'לא ידוע';
                final phoneNumber = userDoc['phoneNumber'] ?? 'לא ידוע';

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 85,
                            backgroundColor: Colors.blue.shade700,
                            child: CircleAvatar(
                              radius: 80,
                              backgroundImage: profilePicture.isNotEmpty
                                  ? NetworkImage(profilePicture)
                                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                              child: profilePicture.isEmpty
                                  ? const Icon(Icons.person, size: 80, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 5,
                            bottom: 5,
                            child: GestureDetector(
                              onTap: _showOptions,
                              child: const CircleAvatar(
                                backgroundColor: Colors.white,
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
                Text(field, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade600)),
                Text(value, style: const TextStyle(fontSize: 16.0, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
