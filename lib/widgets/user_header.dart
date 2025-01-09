import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHeader extends StatefulWidget {
  const UserHeader({Key? key}) : super(key: key);

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _fullName,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 8.0),
        CircleAvatar(
          radius: 20,
          backgroundImage: _profilePicture != null && _profilePicture!.isNotEmpty
              ? NetworkImage(_profilePicture!)
              : const AssetImage('assets/images/default_profile.png')
                  as ImageProvider,
          child: _profilePicture == null || _profilePicture!.isEmpty
              ? const Icon(Icons.person, size: 20)
              : null,
        ),
      ],
    );
  }
}
