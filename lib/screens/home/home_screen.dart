import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/screens/reports/worker_reports_screen.dart';
import 'package:park_janana/services/clock_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/user_card.dart';
import 'package:park_janana/widgets/custom_card.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';
import 'package:park_janana/screens/shifts/shifts_screen.dart';
import 'package:park_janana/screens/shifts/manager_shifts_screen.dart';
import 'package:park_janana/screens/tasks/worker_task_screen.dart';
import 'package:park_janana/screens/tasks/manager_task_dashboard.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:park_janana/screens/workers_management/manage_workers_screen.dart';
import 'package:park_janana/widgets/clock_in_out_widget.dart';

class HomeScreen extends StatefulWidget {
  final String role;

  const HomeScreen({super.key, required this.role});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _profilePictureUrl;
  Map<String, dynamic>? _roleData;
  Map<String, dynamic>? _userData;
  Map<String, double>? _workStats;

  static final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _loadRolesData();
    _loadData();
  }

  Future<void> _loadRolesData() async {
    final String rolesJson = await rootBundle.loadString('lib/config/roles.json');
    if (!mounted) return;
    setState(() {
      _roleData = json.decode(rolesJson);
    });
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final userData = await _fetchUserData(uid);
    final stats = await ClockService().getMonthlyWorkStats(uid);

    if (mounted) {
      setState(() {
        _userData = userData;
        _workStats = {
          'hoursWorked': stats['hoursWorked']?.toDouble() ?? 0.0,
          'daysWorked': stats['daysWorked']?.toDouble() ?? 0.0,
        };
      });
    }
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _userData == null || _workStats == null
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            UserCard(
                              userName: _userData!['fullName'] ?? 'משתמש',
                              profilePictureUrl: _profilePictureUrl ??
                                  _userData!['profile_picture'] ??
                                  'https://via.placeholder.com/150',
                              currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
                              daysWorked: _workStats!['daysWorked']!.toInt(),
                              hoursWorked: _workStats!['hoursWorked']!,
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 16,
                                runSpacing: 16,
                                children: _buildActionButtons(
                                  _userData!['role'] ?? 'worker',
                                  currentUser.uid,
                                ).reversed.toList(),
                              ),
                            ),
                            const Spacer(),
                            const ClockInOutWidget(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  List<Widget> _buildActionButtons(String role, String uid) {
    List<Widget> buttons = [
      CustomCard(
        title: 'פרופיל',
        icon: Icons.person,
        onTap: () {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalAreaScreen(uid: uid),
            ),
          );
        },
      ),

      CustomCard(
  title: 'דוחות',
  icon: Icons.bar_chart,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WorkerReportsScreen(
          userId: uid,
          userName: _userData!['fullName'] ?? 'משתמש',
          profileUrl: _userData!['profile_picture'] ?? '',
        ),
      ),
    );
  },
),

    ];

    if (_roleData != null && _roleData!.containsKey(role)) {
      buttons.addAll(
        (_roleData![role] as List<dynamic>).map<Widget>((operation) {
          return CustomCard(
            title: operation['title'],
            icon: IconData(operation['icon'], fontFamily: 'MaterialIcons'),
            onTap: () {
              debugPrint('${operation['title']} tapped');
            },
          );
        }),
      );
    }

    if (role == 'worker') {
      buttons.addAll([
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
      ]);
    }

    if (role == 'manager') {
      buttons.addAll([
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
      ]);
    }

    if (role == 'owner') {
      buttons.add(
        CustomCard(
          title: 'דוחות עסקיים',
          icon: Icons.bar_chart,
          onTap: () {
            debugPrint('דוחות tapped');
          },
        ),
      );
    }

    return buttons;
  }
}
