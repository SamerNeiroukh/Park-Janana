import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/user_card.dart';
import 'package:park_janana/widgets/custom_card.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';
import 'package:park_janana/screens/shifts/shifts_screen.dart';
import 'package:park_janana/screens/shifts/manager_shifts_screen.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HomeScreen extends StatefulWidget {
  final String role;

  const HomeScreen({super.key, required this.role});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profilePictureUrl;
  Map<String, dynamic>? _roleData;

  // ✅ Cache for user data
  static final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadRolesData();
  }

  Future<void> _loadRolesData() async {
    final String rolesJson = await rootBundle.loadString('lib/config/roles.json');
    setState(() {
      _roleData = json.decode(rolesJson);
    });
  }

  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    // ✅ First check if user data is cached
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // ✅ Store user data in cache
        _userCache[uid] = userData;

        return userData;
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('לא נמצא משתמש מחובר', style: AppTheme.bodyText), // ✅ Use themed text
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
            return Center(
              child: Text('שגיאה בטעינת הנתונים', style: AppTheme.bodyText),
            );
          }

          final userData = snapshot.data!;
          final String role = userData['role'] ?? 'worker';
          debugPrint('Fetched User Role: $role');

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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'פעולות',
                  style: AppTheme.sectionTitle, // ✅ Use the theme for section titles
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonalAreaScreen(uid: currentUser.uid),
                          ),
                        );
                      },
                    ),
                    if (_roleData != null && _roleData![role] != null)
                      ..._roleData![role].map<Widget>((operation) {
                        return CustomCard(
                          title: operation['title'],
                          icon: IconData(operation['icon'], fontFamily: 'MaterialIcons'),
                          onTap: () {
                            debugPrint('${operation['title']} tapped');
                          },
                        );
                      }).toList(),
                    if (role == 'manager')
                      CustomCard(
                        title: 'ניהול משמרות',
                        icon: Icons.schedule,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManagerShiftsScreen(),
                            ),
                          );
                        },
                      ),
                    if (role == 'worker')
                      CustomCard(
                        title: 'משמרות',
                        icon: Icons.access_time,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ShiftsScreen(),
                            ),
                          );
                        },
                      ),
                    if (role == 'owner')
                      CustomCard(
                        title: 'דוחות עסקיים',
                        icon: Icons.bar_chart,
                        onTap: () {
                          debugPrint('דוחות עסקיים tapped');
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
