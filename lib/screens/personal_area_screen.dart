import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:park_janana/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _confirmUpload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected.")),
      );
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      try {
        final storageRef = _storage.ref().child('profile_pictures/${widget.uid}.jpg');
        await storageRef.putFile(_imageFile!);
        final downloadUrl = await storageRef.getDownloadURL();
        await _authService.updateProfilePicture(widget.uid, downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error uploading image: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No image selected.")),
      );
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      await _authService.updateProfilePicture(widget.uid, '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture deleted.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting image: $e")),
      );
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
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("מחק תמונה", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteProfilePicture();
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

  void _updatePhoneNumber(String newPhone) async {
    try {
      await _firestore.collection('users').doc(widget.uid).update({'phoneNumber': newPhone});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number updated.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating phone number: $e")),
      );
    }
  }

  void _editPhoneNumber(String currentPhone) {
    final TextEditingController phoneController = TextEditingController(text: currentPhone);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("עדכן מספר טלפון"),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            textAlign: TextAlign.right,
            decoration: const InputDecoration(hintText: "הכנס מספר חדש"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("ביטול"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updatePhoneNumber(phoneController.text.trim());
              },
              child: const Text("שמור"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('אזור אישי'),
      ),
      body: Center(
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
                  GestureDetector(
                    onTap: _showOptions,
                    child: CircleAvatar(
                      radius: 80,
                      backgroundImage: profilePicture.isNotEmpty
                          ? NetworkImage(profilePicture)
                          : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                      child: profilePicture.isEmpty
                          ? const Icon(Icons.person, size: 80)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(Icons.person, "שם מלא", fullName),
                  _buildInfoRow(Icons.email, "אימייל", email),
                  _buildInfoRow(Icons.badge, "תעודת זהות", idNumber),
                  _buildEditableInfoRow(Icons.phone, "מספר טלפון", phoneNumber),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String field, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(field, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoRow(IconData icon, String field, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(field, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(value),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.grey),
            onPressed: () => _editPhoneNumber(value),
          ),
        ],
      ),
    );
  }
}
