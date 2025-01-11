import 'package:flutter/material.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/user_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/widgets/custom_card.dart';
import 'package:park_janana/screens/personal_area_screen.dart';

class HomeScreen extends StatefulWidget {
  final String role;

  const HomeScreen({super.key, required this.role});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profilePictureUrl;

  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return {}; // Return an empty map if the document does not exist or an error occurs
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('לא נמצא משתמש מחובר', style: TextStyle(fontSize: 18.0)),
        ),
      );
    }

    return Scaffold(
      appBar: const UserHeader(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            debugPrint('Error or no data: ${snapshot.error}');
            return const Center(child: Text('שגיאה בטעינת הנתונים'));
          }

          final userData = snapshot.data!;
          debugPrint('Fetched User Data: $userData');

          final String userName = userData['fullName'] ?? 'משתמש';
          final String profilePictureUrl =
              _profilePictureUrl ?? userData['profile_picture'] ?? 'https://via.placeholder.com/150';
          final String currentDate =
              DateFormat('dd/MM/yyyy').format(DateTime.now());
          final int daysWorked = userData['daysWorked'] ?? 0;
          final int hoursWorked = userData['hoursWorked'] ?? 0;

          return Column(
            children: [
              UserCard(
                userName: userName,
                profilePictureUrl: profilePictureUrl,
                currentDate: currentDate,
                daysWorked: daysWorked,
                hoursWorked: hoursWorked,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'פעולות',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 140.0,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  children: [
                    CustomCard(
                      title: 'פרופיל',
                      icon: Icons.person,
                      onTap: () async {
                        // Navigate to PersonalAreaScreen and wait for the updated profile picture URL
                        final updatedProfilePictureUrl = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PersonalAreaScreen(uid: currentUser.uid),
                          ),
                        );

                        // Update the profile picture if a new URL is returned
                        if (updatedProfilePictureUrl != null) {
                          setState(() {
                            _profilePictureUrl = updatedProfilePictureUrl;
                          });
                        }
                      },
                    ),
                    CustomCard(
                      title: 'שעות עבודה',
                      icon: Icons.schedule,
                      onTap: () {
                        debugPrint('Working hours tapped');
                      },
                    ),
                    CustomCard(
                      title: 'משימות',
                      icon: Icons.task,
                      onTap: () {
                        debugPrint('Tasks tapped');
                      },
                    ),
                    CustomCard(
                      title: 'דוחות',
                      icon: Icons.report,
                      onTap: () {
                        debugPrint('Reports tapped');
                      },
                    ),
                    CustomCard(
                      title: 'הגדרות',
                      icon: Icons.settings,
                      onTap: () {
                        debugPrint('Settings tapped');
                      },
                    ),
                    CustomCard(
                      title: 'עזרה',
                      icon: Icons.help,
                      onTap: () {
                        debugPrint('Help tapped');
                      },
                    ),
                    CustomCard(
                      title: 'מיקום',
                      icon: Icons.location_on,
                      onTap: () {
                        debugPrint('Location tapped');
                      },
                    ),
                    CustomCard(
                      title: 'טלפון',
                      icon: Icons.phone,
                      onTap: () {
                        debugPrint('Phone tapped');
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
