import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/services/clock_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/user_card.dart';
import 'package:park_janana/widgets/custom_card.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';
import 'package:park_janana/screens/shifts/shifts_screen.dart';
import 'package:park_janana/screens/shifts/manager_shifts_screen.dart';
import 'package:park_janana/screens/tasks/worker_task_screen.dart';
import 'package:park_janana/screens/tasks/manager_task_dashboard.dart';
import 'package:park_janana/screens/workers_management/manage_workers_screen.dart';
import 'package:park_janana/widgets/clock_in_out_widget.dart';
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
  static final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadRolesData();
  }

  Future<void> _loadRolesData() async {
    final String rolesJson =
        await rootBundle.loadString('lib/config/roles.json');
    if (!mounted) return;
    setState(() {
      _roleData = json.decode(rolesJson);
    });
  }

  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    if (_userCache.containsKey(uid)) {
      return _userCache[uid]!;
    }

    try {
      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
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
          child: Text('לא נמצא משתמש מחובר', style: AppTheme.bodyText),
        ),
      );
    }

    return Scaffold(
      appBar: const UserHeader(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchUserData(currentUser.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (userSnapshot.hasError || userSnapshot.data == null) {
            return Center(
              child: Text('שגיאה בטעינת הנתונים', style: AppTheme.bodyText),
            );
          }

          final userData = userSnapshot.data!;
          final String role = userData['role'] ?? 'worker';
          final String userName = userData['fullName'] ?? 'משתמש';
          final String profilePictureUrl = _profilePictureUrl ??
              userData['profile_picture'] ??
              'https://via.placeholder.com/150';
          final String currentDate =
              DateFormat('dd/MM/yyyy').format(DateTime.now());

          return FutureBuilder<Map<String, int>>(
            future: ClockService().getMonthlyWorkStats(currentUser.uid),
            builder: (context, statsSnapshot) {
              if (statsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final int daysWorked = statsSnapshot.data?['daysWorked'] ?? 0;
              final double hoursWorked = statsSnapshot.data != null
                  ? statsSnapshot.data!['hoursWorked']!.toDouble()
                  : 0;

              final List<Widget> actionButtons = [
                CustomCard(
                  title: 'פרופיל',
                  icon: Icons.person,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PersonalAreaScreen(uid: currentUser.uid),
                      ),
                    );
                  },
                ),
                if (_roleData != null && _roleData!.containsKey(role))
                  ...(_roleData![role] as List<dynamic>)
                      .map<Widget>((operation) {
                    return CustomCard(
                      title: operation['title'],
                      icon: IconData(operation['icon'],
                          fontFamily: 'MaterialIcons'),
                      onTap: () {
                        debugPrint('${operation['title']} tapped');
                      },
                    );
                  }),
                if (role == 'worker') ...[
                  CustomCard(
                    title: 'משימות שלי',
                    icon: Icons.task,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WorkerTaskScreen(),
                        ),
                      );
                    },
                  ),
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
                ],
                if (role == 'manager') ...[
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
                  CustomCard(
                    title: 'ניהול משימות',
                    icon: Icons.task,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManagerTaskDashboard(),
                        ),
                      );
                    },
                  ),
                  CustomCard(
                    title: 'ניהול עובדים',
                    icon: Icons.manage_accounts,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageWorkersScreen(),
                        ),
                      );
                    },
                  ),
                ],
                if (role == 'owner')
                  CustomCard(
                    title: 'דוחות עסקיים',
                    icon: Icons.bar_chart,
                    onTap: () {
                      debugPrint('דוחות tapped');
                    },
                  ),
              ];

              return Column(
                children: [
                  UserCard(
                    userName: userName,
                    profilePictureUrl: profilePictureUrl,
                    currentDate: currentDate,
                    daysWorked: daysWorked,
                    hoursWorked: hoursWorked,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      runSpacing: 16,
                      children: actionButtons.reversed.toList(),
                    ),
                  ),
                  const Spacer(),
                  const ClockInOutWidget(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
