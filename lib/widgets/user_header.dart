import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHeader extends StatefulWidget {
  const UserHeader({super.key});

  @override
  _UserHeaderState createState() => _UserHeaderState();
}

class _UserHeaderState extends State<UserHeader> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _fullName = "User";
  String? _profilePicture;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        setState(() {
          _fullName = userDoc.get('fullName') ?? "User";
          _profilePicture = userDoc.get('profile_picture');
        });
      } catch (e) {
        print('Error fetching user details: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Container(); // Return empty widget if no user is logged in.
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(currentUser.uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("Error loading user data");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show loading spinner.
        }

        if (snapshot.hasData) {
          var data = snapshot.data?.data() as Map<String, dynamic>?;

          String fullName = data?['fullName'] ?? "User";
          String? profilePicture = data?['profile_picture'];

          return Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 5.0), // Adjusted spacing to move higher
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12.0),
                CircleAvatar(
                  radius: 24,
                  backgroundImage: profilePicture != null && profilePicture.isNotEmpty
                      ? NetworkImage(profilePicture)
                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                  child: profilePicture == null || profilePicture.isEmpty
                      ? const Icon(Icons.person, size: 24, color: Colors.white)
                      : null,
                ),
              ],
            ),
          );
        }

        return const Text("No user data available");
      },
    );
  }
}
