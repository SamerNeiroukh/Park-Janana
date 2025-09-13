import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/screens/reports/worker_reports_screen.dart';
import 'package:park_janana/services/clock_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/user_card.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';
import 'package:park_janana/screens/shifts/shifts_screen.dart';
import 'package:park_janana/screens/shifts/manager_shifts_screen.dart';
import 'package:park_janana/screens/tasks/worker_task_screen.dart';
import 'package:park_janana/screens/tasks/manager_task_dashboard.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:park_janana/screens/workers_management/manage_workers_screen.dart';
import 'package:park_janana/widgets/clock_in_out_widget.dart';
import 'package:park_janana/widgets/custom_card.dart';
import 'package:park_janana/services/weather_service.dart';

class HomeScreen extends StatefulWidget {
  final String role;

  const HomeScreen({
    super.key,
    required this.role,
    this.firebaseAuth, // <-- test seam
    this.testMode = false, // <-- skip async + Firebase in tests
  });

  final FirebaseAuth? firebaseAuth; // <-- optional injected auth
  final bool testMode;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _roleData;
  Map<String, dynamic>? _userData;
  Map<String, double>? _workStats;
  Map<String, dynamic>? _weatherData;

  static final Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();

    if (widget.testMode) {
      // Minimal, deterministic state for widget tests (no Firebase/IO).
      _roleData = null;
      _userData = {
        'fullName': 'QA User',
        'profile_picture': '',
        'role': 'worker',
      };
      _workStats = {
        'hoursWorked': 0.0,
        'daysWorked': 0.0,
      };
      _weatherData = {
        'description': 'clear',
        'temperature': '20',
        'icon': null,
      };
      setState(() {}); // trigger first build
      return; // <-- skip all async/Firebase calls
    }

    _loadRolesData();
    _loadData();
  }

  Future<void> _loadRolesData() async {
    final String rolesJson =
        await rootBundle.loadString('lib/config/roles.json');
    if (!mounted) return;
    setState(() {
      _roleData = json.decode(rolesJson);
    });
  }

  Future<void> _loadData() async {
    final uid = (widget.firebaseAuth ?? FirebaseAuth.instance).currentUser?.uid;
    if (uid == null) return;

    final userData = await _fetchUserData(uid);
    final stats = await ClockService().getMonthlyWorkStats(uid);
    final weather = await WeatherService().fetchWeather();

    if (mounted) {
      setState(() {
        _userData = userData;
        _weatherData = weather;
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
    // In tests, avoid any animated/network/Firebase widgets entirely.
    if (widget.testMode) {
      return const Scaffold(
        body: Center(child: Text('Home (test)')),
      );
    }

    final User? currentUser =
        (widget.firebaseAuth ?? FirebaseAuth.instance).currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('לא נמצא משתמש מחובר', style: AppTheme.bodyText),
        ),
      );
    }

    return Scaffold(
      appBar: const UserHeader(),
      body: _userData == null || _workStats == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.00,
                      vertical: screenHeight * 0.01,
                    ),
                    child: widget.testMode
                        ? const SizedBox(
                            height: 1) // avoid NetworkImage in tests
                        : UserCard(
                            userName: _userData!['fullName'] ?? 'משתמש',
                            profilePictureUrl:
                                _userData!['profile_picture'] ?? '',
                            currentDate:
                                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                            daysWorked: _workStats!['daysWorked']!.toInt(),
                            hoursWorked: _workStats!['hoursWorked']!,
                            weatherDescription: _weatherData?['description'],
                            temperature:
                                _weatherData?['temperature']?.toString(),
                            weatherIcon: _weatherData?['icon'],
                          ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                    child: ActionButtonGridPager(
                      buttons: _buildActionButtons(
                          _userData!['role'] ?? 'worker', currentUser.uid),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenHeight * 0.005,
                    ),
                    child: widget.testMode
                        ? const SizedBox
                            .shrink() // <-- avoid Firestore in tests
                        : const ClockInOutWidget(),
                  ),
                ],
              ),
            ),
    );
  }

  List<ActionButton> _buildActionButtons(String role, String uid) {
    List<ActionButton> buttons = [
      ActionButton(
        title: 'פרופיל',
        icon: Icons.person_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PersonalAreaScreen(uid: uid)),
          );
        },
      ),
      ActionButton(
        title: 'הדו\"חות שלי',
        icon: Icons.stacked_bar_chart_rounded,
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
        (_roleData![role] as List<dynamic>).map<ActionButton>((operation) {
          return ActionButton(
            title: operation['title'],
            icon: IconData(operation['icon'], fontFamily: 'MaterialIcons'),
            onTap: () {
              debugPrint('${operation['title']} tapped');
            },
          );
        }).toList(),
      );
    }

    if (role == 'worker') {
      buttons.addAll([
        ActionButton(
          title: 'המשימות שלי',
          icon: Icons.check_circle_outline_rounded,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WorkerTaskScreen()));
          },
        ),
        ActionButton(
          title: 'המשמרות שלי',
          icon: Icons.schedule_outlined,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShiftsScreen()));
          },
        ),
      ]);
    }

    if (role == 'manager') {
      buttons.addAll([
        ActionButton(
          title: 'ניהול משמרות',
          icon: Icons.manage_history_rounded,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ManagerShiftsScreen()));
          },
        ),
        ActionButton(
          title: 'ניהול משימות',
          icon: Icons.assignment_turned_in_rounded,
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManagerTaskDashboard()));
          },
        ),
        ActionButton(
          title: 'ניהול עובדים',
          icon: Icons.group,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ManageWorkersScreen()));
          },
        ),
      ]);
    }

    if (role == 'owner') {
      buttons.add(
        ActionButton(
          title: 'דו\"חות עסקיים',
          icon: Icons.bar_chart_rounded,
          onTap: () => debugPrint('דוחות עסקיים tapped'),
        ),
      );
    }

    return buttons;
  }
}
