import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

// ── Navigation targets (ALL UNCHANGED) ───────────────────────────────────
import 'package:park_janana/features/reports/screens/worker_reports_screen.dart';
import 'package:park_janana/features/reports/screens/manager_reports_screen.dart';
import 'package:park_janana/features/home/screens/personal_area_screen.dart';
import 'package:park_janana/features/shifts/screens/shifts_screen.dart';
import 'package:park_janana/features/shifts/screens/manager_shifts_screen.dart';
import 'package:park_janana/features/shifts/screens/manager_weekly_schedule_screen.dart';
import 'package:park_janana/features/shifts/screens/my_weekly_schedule_screen.dart';
import 'package:park_janana/features/tasks/screens/worker_task_timeline_screen.dart';
import 'package:park_janana/features/tasks/screens/manager_task_board_screen.dart';
import 'package:park_janana/features/workers/screens/manage_workers_screen.dart';
import 'package:park_janana/features/newsfeed/screens/newsfeed_screen.dart';
import 'package:park_janana/features/notifications/screens/notification_history_screen.dart';
import 'package:park_janana/features/settings/screens/settings_screen.dart';

// ── Providers (ALL UNCHANGED) ─────────────────────────────────────────────
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/providers/app_state_provider.dart';
import 'package:park_janana/features/home/providers/home_badge_provider.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';


// ── Home UI components ────────────────────────────────────────────────────
import 'package:park_janana/features/home/widgets/home_top_bar.dart';
import 'package:park_janana/features/home/widgets/glass_hero_card.dart';
import 'package:park_janana/features/home/widgets/latest_post_card.dart';

// ── Design tokens ─────────────────────────────────────────────────────────
const _kBg = Color(0xFFF0F2FC);
const _kPrimary = Color(0xFF4F46E5);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _badgeInitialized = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadCurrentUser();
      context.read<UserProvider>().loadWorkStats();
      context.read<AppStateProvider>().loadWeather();
      context.read<AppStateProvider>().loadRolesData();
      _fadeCtrl.forward();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _navigateToProfile(String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PersonalAreaScreen(uid: uid)),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final appStateProvider = context.watch<AppStateProvider>();
    final authProvider = context.watch<AppAuthProvider>();
    final badgeProvider = context.watch<HomeBadgeProvider>();

    final currentUser = authProvider.user;

    // Still loading
    if (currentUser == null || userProvider.isLoading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Load finished but user data unavailable (offline + no Firestore cache)
    if (userProvider.currentUser == null) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'אין חיבור לאינטרנט',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'לא ניתן לטעון את הנתונים.\nבדוק את החיבור ונסה שוב.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () {
                      context.read<UserProvider>().loadCurrentUser();
                      context.read<UserProvider>().loadWorkStats();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('נסה שוב'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final userData = userProvider.currentUser!;
    final workStats =
        userProvider.workStats ?? {'hoursWorked': 0.0, 'daysWorked': 0.0};
    final weatherData = appStateProvider.weatherData;

    // Wire badge provider once
    if (!_badgeInitialized) {
      _badgeInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        badgeProvider.init(userId: currentUser.uid, userRole: userData.role);
      });
    }

    final shiftsBadge = badgeProvider.getBadgeCount('shifts');
    final tasksBadge = badgeProvider.getBadgeCount('tasks');
    final newsfeedBadge = badgeProvider.getBadgeCount('newsfeed');
    final totalBadge = shiftsBadge + tasksBadge + newsfeedBadge;

    final dept = userData.licensedDepartments.isNotEmpty
        ? userData.licensedDepartments.first
        : '';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  // ── Decorative background blobs ──────────────────────
                  Positioned(
                    top: -50,
                    right: -70,
                    child: Container(
                      width: 260,
                      height: 260,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF6D28D9).withOpacity(0.10),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 80,
                    left: -60,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF4F46E5).withOpacity(0.06),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Scrollable content ───────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── 1. TOP BAR (logo centred, RTL) ────────
                          HomeTopBar(
                            profilePictureUrl: userData.profilePicture,
                            notificationBadgeCount: totalBadge,
                            onProfileTap: () =>
                                _navigateToProfile(currentUser.uid),
                            onNotificationTap: () {
                              // Clear all section badges when opening notifications
                              badgeProvider.markSectionVisited('shifts');
                              badgeProvider.markSectionVisited('tasks');
                              badgeProvider.markSectionVisited('newsfeed');
                              badgeProvider.markSectionVisited('schedule');
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const NotificationHistoryScreen()),
                              );
                            },
                            onSettingsTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsScreen()),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ── 2. GLASS HERO CARD (clock built-in) ──
                          GlassHeroCard(
                            userName: userData.fullName,
                            daysWorked:
                                (workStats['daysWorked'] as double).toInt(),
                            hoursWorked: workStats['hoursWorked'] as double,
                            weatherDescription: weatherData?['description'],
                            temperature:
                                weatherData?['temperature']?.toString(),
                            department: dept.isNotEmpty ? dept : null,
                            roleIcon: _roleIcon(userData.role),
                            onClockComplete: () =>
                                context.read<UserProvider>().loadWorkStats(),
                          ),

                          const SizedBox(height: 16),

                          // ── 3. HORIZONTAL ACTION STRIP ────────────
                          _HorizontalActionStrip(
                            items: _buildStripItems(
                              userData.role,
                              currentUser.uid,
                              userData.fullName,
                              userData.profilePicture,
                              badgeProvider,
                              appStateProvider,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── 5. LATEST POST CARD ───────────────────
                          LatestPostCard(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NewsfeedScreen()),
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Role icon derivation ───────────────────────────────────────────────

  IconData _roleIcon(String role) {
    switch (role) {
      case 'worker':
        return Icons.badge_rounded;
      case 'manager':
        return Icons.supervisor_account_rounded;
      default:
        return Icons.business_rounded;
    }
  }

  // ── Strip items: primary CTA first, no notifications/settings ─────────

  List<_StripItem> _buildStripItems(
    String role,
    String uid,
    String userName,
    String profileUrl,
    HomeBadgeProvider badgeProvider,
    AppStateProvider appStateProvider,
  ) {
    final items = <_StripItem>[];

    if (role == 'worker') {
      items.addAll([
        // Primary CTA (first = rightmost in RTL strip)
        _StripItem(
          icon: Icons.schedule_rounded,
          label: 'משמרות',
          badge: badgeProvider.getBadgeCount('shifts'),
          color: _kPrimary,
          onTap: () {
            badgeProvider.markSectionVisited('shifts');
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ShiftsScreen()));
          },
        ),
        _StripItem(
          icon: Icons.calendar_view_week_rounded,
          label: 'סידור עבודה',
          badge: badgeProvider.getBadgeCount('schedule'),
          color: const Color(0xFF6366F1),
          onTap: () {
            badgeProvider.markSectionVisited('schedule');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyWeeklyScheduleScreen()));
          },
        ),
        _StripItem(
          icon: Icons.task_alt_rounded,
          label: 'משימות',
          badge: badgeProvider.getBadgeCount('tasks'),
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const WorkerTaskTimelineScreen())),
        ),
        _StripItem(
          icon: Icons.bar_chart_rounded,
          label: 'דוחות',
          color: const Color(0xFF22C55E),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkerReportsScreen(
                      userId: uid,
                      userName: userName,
                      profileUrl: profileUrl))),
        ),
        _StripItem(
          icon: Icons.newspaper_rounded,
          label: 'לוח מודעות',
          badge: badgeProvider.getBadgeCount('newsfeed'),
          color: const Color(0xFFF59E0B),
          onTap: () {
            badgeProvider.markSectionVisited('newsfeed');
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NewsfeedScreen()));
          },
        ),
      ]);
    } else if (role == 'manager') {
      items.addAll([
        // Primary CTA
        _StripItem(
          icon: Icons.manage_history_rounded,
          label: 'משמרות',
          badge: badgeProvider.getBadgeCount('shifts'),
          color: _kPrimary,
          onTap: () {
            badgeProvider.markSectionVisited('shifts');
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ManagerShiftsScreen()));
          },
        ),
        _StripItem(
          icon: Icons.calendar_view_week_rounded,
          label: 'סידור שבועי',
          badge: badgeProvider.getBadgeCount('schedule'),
          color: const Color(0xFF6366F1),
          onTap: () {
            badgeProvider.markSectionVisited('schedule');
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ManagerWeeklyScheduleScreen()));
          },
        ),
        _StripItem(
          icon: Icons.assignment_rounded,
          label: 'משימות',
          badge: badgeProvider.getBadgeCount('tasks'),
          color: const Color(0xFF8B5CF6),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ManagerTaskBoardScreen())),
        ),
        _StripItem(
          icon: Icons.group_rounded,
          label: 'ניהול עובדים',
          color: const Color(0xFF0EA5E9),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManageWorkersScreen())),
        ),
        _StripItem(
          icon: Icons.stacked_bar_chart_rounded,
          label: 'דוחות',
          color: const Color(0xFF22C55E),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ManagerReportsScreen(
                      userId: uid,
                      userName: userName,
                      profileUrl: profileUrl))),
        ),
        _StripItem(
          icon: Icons.newspaper_rounded,
          label: 'לוח מודעות',
          badge: badgeProvider.getBadgeCount('newsfeed'),
          color: const Color(0xFFF59E0B),
          onTap: () {
            badgeProvider.markSectionVisited('newsfeed');
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NewsfeedScreen()));
          },
        ),
      ]);
    } else {
      // owner
      items.addAll([
        // Primary CTA
        _StripItem(
          icon: Icons.newspaper_rounded,
          label: 'לוח מודעות',
          badge: badgeProvider.getBadgeCount('newsfeed'),
          color: _kPrimary,
          onTap: () {
            badgeProvider.markSectionVisited('newsfeed');
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NewsfeedScreen()));
          },
        ),
        _StripItem(
          icon: Icons.bar_chart_rounded,
          label: 'דו"חות עסקיים',
          color: const Color(0xFF22C55E),
          onTap: () {},
        ),
        _StripItem(
          icon: Icons.stacked_bar_chart_rounded,
          label: 'דו"חות אישיים',
          color: const Color(0xFFF59E0B),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkerReportsScreen(
                      userId: uid,
                      userName: userName,
                      profileUrl: profileUrl))),
        ),
      ]);
    }

    // Dynamic role operations from roles.json (preserved)
    for (final op in appStateProvider.getOperationsForRole(role)) {
      items.add(_StripItem(
        icon: IconData(op['icon'] as int, fontFamily: 'MaterialIcons'),
        label: op['title'] as String,
        color: _kPrimary,
        onTap: () {},
      ));
    }

    return items;
  }
}

// ══════════════════════════════════════════════════════════════════════════
//  PRIVATE WIDGETS
// ══════════════════════════════════════════════════════════════════════════

// ── Strip item data model ─────────────────────────────────────────────────

class _StripItem {
  final IconData icon;
  final String label;
  final int badge;
  final Color color;
  final VoidCallback onTap;

  const _StripItem({
    required this.icon,
    required this.label,
    this.badge = 0,
    required this.color,
    required this.onTap,
  });
}

// ── Action grid — 3 columns, RTL ─────────────────────────────────────────

class _HorizontalActionStrip extends StatelessWidget {
  final List<_StripItem> items;

  const _HorizontalActionStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // RTL: first item is top-right
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _StripPill(item: items[i]),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 380.ms, delay: 100.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 380.ms,
            delay: 100.ms,
            curve: Curves.easeOut);
  }
}

// ── Strip pill button ─────────────────────────────────────────────────────

class _StripPill extends StatefulWidget {
  final _StripItem item;

  const _StripPill({required this.item});

  @override
  State<_StripPill> createState() => _StripPillState();
}

class _StripPillState extends State<_StripPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.item.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Circular gradient icon
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.item.color,
                    widget.item.color.withOpacity(0.70),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.item.color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.item.icon,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            // Label below
            Text(
              widget.item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
