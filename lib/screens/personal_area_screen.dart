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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
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

        // Upload the file
        await storageRef.putFile(_imageFile!);

        // Get the download URL
        final downloadUrl = await storageRef.getDownloadURL();

        // Update the profile picture URL in Firestore
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Area'),
      ),
      body: Center(
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestore.collection('users').doc(widget.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text("Error loading profile picture.");
            }

            if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            final userDoc = snapshot.data!;
            final profilePicture = userDoc['profile_picture'] ?? '';

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                  child: profilePicture.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo),
                  label: const Text("Choose Profile Picture"),
                ),
                ElevatedButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("Upload Profile Picture"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
