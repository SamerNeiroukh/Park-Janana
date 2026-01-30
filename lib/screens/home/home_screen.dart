import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/screens/reports/worker_reports_screen.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/user_card.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';
import 'package:park_janana/screens/shifts/shifts_screen.dart';
import 'package:park_janana/screens/shifts/manager_shifts_screen.dart';
import 'package:park_janana/screens/shifts/weekly_schedule_screen.dart';
import 'package:park_janana/screens/tasks/worker_task_screen.dart';
import 'package:park_janana/screens/tasks/manager_task_dashboard.dart';
import 'package:park_janana/screens/workers_management/manage_workers_screen.dart';
import 'package:park_janana/widgets/clock_in_out_widget.dart';
import 'package:park_janana/widgets/custom_card.dart';
import 'package:park_janana/providers/user_provider.dart';
import 'package:park_janana/providers/app_state_provider.dart';
import 'package:park_janana/providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load data from providers on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      final appStateProvider = context.read<AppStateProvider>();

      // Load user data and work stats
      userProvider.loadCurrentUser();
      userProvider.loadWorkStats();

      // Load app-wide data
      appStateProvider.loadWeather();
      appStateProvider.loadRolesData();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for automatic updates
    final userProvider = context.watch<UserProvider>();
    final appStateProvider = context.watch<AppStateProvider>();
    final authProvider = context.watch<AppAuthProvider>();

    final currentUser = authProvider.user;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
          child: Text('לא נמצא משתמש מחובר', style: AppTheme.bodyText),
        ),
      );
    }

    // Show loading while data is being fetched
    if (userProvider.isLoading || userProvider.currentUser == null) {
      return Scaffold(
        appBar: const UserHeader(showLogoutButton: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userData = userProvider.currentUser!;
    final workStats = userProvider.workStats ?? {'hoursWorked': 0.0, 'daysWorked': 0.0};
    final weatherData = appStateProvider.weatherData;

    return Scaffold(
      appBar: const UserHeader(showLogoutButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          children: [
            UserCard(
              userName: userData.fullName,
              profilePictureUrl: userData.profilePicture,
              profilePicturePath: userData.profilePicturePath,
              currentDate: DateFormat('dd/MM/yyyy').format(DateTime.now()),
              daysWorked: (workStats['daysWorked'] as double).toInt(),
              hoursWorked: workStats['hoursWorked'] as double,
              weatherDescription: weatherData?['description'],
              temperature: weatherData?['temperature']?.toString(),
              weatherIcon: weatherData?['icon'],
              onProfileUpdated: () {
                // Refresh user data after profile update
                context.read<UserProvider>().refresh();
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ActionButtonGridPager(
                buttons: _buildActionButtons(
                  userData.role,
                  currentUser.uid,
                  userData.fullName,
                  userData.profilePicture,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: ClockInOutWidget(),
            ),
          ],
        ),
      ),
    );
  }

  List<ActionButton> _buildActionButtons(
    String role,
    String uid,
    String userName,
    String profileUrl,
  ) {
    // Get role operations from provider
    final appStateProvider = context.read<AppStateProvider>();
    final roleOperations = appStateProvider.getOperationsForRole(role);

    List<ActionButton> buttons = [
      ActionButton(
        title: 'פרופיל',
        icon: Icons.person_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PersonalAreaScreen(uid: uid),
            ),
          );
        },
      ),
      ActionButton(
        title: 'הדו"חות שלי',
        icon: Icons.stacked_bar_chart_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WorkerReportsScreen(
                userId: uid,
                userName: userName,
                profileUrl: profileUrl,
              ),
            ),
          );
        },
      ),
    ];

    // Add role-specific operations
    if (roleOperations.isNotEmpty) {
      buttons.addAll(
        roleOperations.map<ActionButton>((operation) {
          return ActionButton(
            title: operation['title'],
            icon: IconData(operation['icon'], fontFamily: 'MaterialIcons'),
            onTap: () {},
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const WorkerTaskScreen(),
              ),
            );
          },
        ),
        ActionButton(
          title: 'המשמרות שלי',
          icon: Icons.schedule_outlined,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ShiftsScreen(),
              ),
            );
          },
        ),
        ActionButton(
          title: 'לוח שבועי',
          icon: Icons.calendar_view_week,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()));
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManagerShiftsScreen(),
              ),
            );
          },
        ),
        ActionButton(
          title: 'לוח שבועי',
          icon: Icons.calendar_view_week,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WeeklyScheduleScreen()));
          },
        ),
        ActionButton(
          title: 'ניהול משימות',
          icon: Icons.assignment_turned_in_rounded,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManagerTaskDashboard(),
              ),
            );
          },
        ),
        ActionButton(
          title: 'ניהול עובדים',
          icon: Icons.group,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ManageWorkersScreen(),
              ),
            );
          },
        ),
      ]);
    }

    if (role == 'owner') {
      buttons.add(
        ActionButton(
          title: 'דו"חות עסקיים',
          icon: Icons.bar_chart_rounded,
          onTap: () {},
        ),
      );
    }

    return buttons;
  }
}
