import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/core/constants/app_constants.dart';

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
import 'package:park_janana/features/home/screens/owner_dashboard_screen.dart';

// ── Providers (ALL UNCHANGED) ─────────────────────────────────────────────
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/providers/app_state_provider.dart';
import 'package:park_janana/features/home/providers/home_badge_provider.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';


// ── Home UI components ────────────────────────────────────────────────────
import 'package:park_janana/core/services/notification_service.dart';
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
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().loadCurrentUser();
      context.read<UserProvider>().loadWorkStats();
      context.read<AppStateProvider>().loadWeather();
      _fadeCtrl.forward();
      // Navigate to the correct screen if the app was launched by tapping
      // a notification while it was fully terminated (not just backgrounded).
      NotificationService().consumePendingNavigation();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<UserProvider>().loadCurrentUser(),
      context.read<UserProvider>().loadWorkStats(),
      context.read<AppStateProvider>().loadWeather(),
    ]);
    if (mounted) setState(() => _refreshKey++);
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

    // Wire badge provider once — use read so this never triggers a rebuild.
    if (!_badgeInitialized) {
      _badgeInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<HomeBadgeProvider>().init(
              userId: currentUser.uid,
              userRole: userData.role,
            );
      });
    }

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
                  // ── Decorative background blobs (static — isolated from rebuilds) ──
                  const Positioned(
                    top: -50,
                    right: -70,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 260,
                        height: 260,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0x1A6D28D9),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 80,
                    left: -60,
                    child: RepaintBoundary(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color(0x0F4F46E5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Scrollable content ───────────────────────────────
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: _kPrimary,
                      displacement: 20,
                      child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── 1. TOP BAR — only rebuilds when total badge count changes ──
                          Selector<HomeBadgeProvider, int>(
                            selector: (_, p) =>
                                p.getBadgeCount('shifts') +
                                p.getBadgeCount('tasks') +
                                p.getBadgeCount('newsfeed'),
                            builder: (_, totalBadge, _) => HomeTopBar(
                              profilePictureUrl: userData.profilePicture,
                              notificationBadgeCount: totalBadge,
                              onProfileTap: () =>
                                  _navigateToProfile(currentUser.uid),
                              onNotificationTap: () {
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

                          // ── 3. UNDERSTAFFED SHIFTS WARNING (managers only) ──
                          if (userData.role == 'manager' ||
                              userData.role == 'co_owner') ...[
                            const SizedBox(height: 16),
                            _UnderstaffedShiftsBanner(
                              key: ValueKey(_refreshKey),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const ManagerWeeklyScheduleScreen()),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // ── 4. HORIZONTAL ACTION STRIP — only rebuilds when badges change ──
                          Consumer<HomeBadgeProvider>(
                            builder: (_, badgeProvider, _) =>
                                _HorizontalActionStrip(
                              items: _buildStripItems(
                                userData.role,
                                currentUser.uid,
                                userData.fullName,
                                userData.profilePicture,
                                badgeProvider,
                              ),
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
      // owner — full manager access + exclusive dashboard
      items.addAll([
        _StripItem(
          icon: Icons.dashboard_rounded,
          label: 'לוח בקרה',
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const OwnerDashboardScreen())),
        ),
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
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManagerTaskBoardScreen())),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Directionality(
          // RTL: first item is top-right
          textDirection: TextDirection.rtl,
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
                    widget.item.color.withValues(alpha: 0.70),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.item.color.withValues(alpha: 0.35),
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

// ── Understaffed shifts banner (managers only) ────────────────────────────

class _UnderstaffedShiftsBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _UnderstaffedShiftsBanner({super.key, required this.onTap});

  @override
  State<_UnderstaffedShiftsBanner> createState() =>
      _UnderstaffedShiftsBannerState();
}

class _UnderstaffedShiftsBannerState extends State<_UnderstaffedShiftsBanner> {
  int _understaffedCount = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final today = '${DateTime.now().day.toString().padLeft(2, '0')}/'
          '${DateTime.now().month.toString().padLeft(2, '0')}/'
          '${DateTime.now().year}';
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.shiftsCollection)
          .where('date', isEqualTo: today)
          .get();
      int count = 0;
      for (final doc in snap.docs) {
        final data = doc.data();
        final max = (data['maxWorkers'] as num?)?.toInt() ?? 0;
        final assigned = (data['assignedWorkerData'] as List?)?.length ?? 0;
        if (max > 0 && assigned / max < 0.5) count++;
      }
      if (mounted) setState(() { _understaffedCount = count; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _understaffedCount == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_understaffedCount משמרות היום חסרות עובדים',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF991B1B),
                        ),
                      ),
                      const Text(
                        'לחץ לסידור שבועי',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFDC2626), size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
