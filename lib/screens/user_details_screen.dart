import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserDetailsScreen extends StatelessWidget {
  final UserModel user;

  const UserDetailsScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("פרופיל משתמש")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(user.profilePicture),
            ),
            SizedBox(height: 10),
            Text(user.fullName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(user.role, style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Future: Add role-based functionalities here
              },
              child: Text("פעולות ניהול"), // "Management Actions"
            ),
          ],
        ),
      ),
    );
  }
}
