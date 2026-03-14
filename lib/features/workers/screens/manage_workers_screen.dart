// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/workers/screens/review_worker_screen.dart';
import 'package:park_janana/features/workers/screens/approve_worker_screen.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/widgets/shimmer_loading.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:park_janana/features/attendance/screens/attendance_correction_screen.dart';

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Workers with an open (unclosed) attendance session this month
  Set<String> _workerIdsWithOpenSession = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _resolveInitialTab();
    _loadAttendanceIssues();
  }

  /// Loads all attendance docs for the current month in a single query,
  /// then finds workers who have an open (unclosed) session.
  Future<void> _loadAttendanceIssues() async {
    try {
      final now = DateTime.now();
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.attendanceCollection)
          .where('year', isEqualTo: now.year)
          .where('month', isEqualTo: now.month)
          .get();

      final ids = <String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        final sessions = data['sessions'] as List<dynamic>? ?? [];
        final hasOpen = sessions.any((s) {
          final map = s as Map<String, dynamic>;
          final ci = (map['clockIn'] as dynamic).toDate() as DateTime;
          final co = (map['clockOut'] as dynamic).toDate() as DateTime;
          // Only flag as missed clock-out if clocked in for 16+ hours without clocking out
          if (ci != co) return false;
          return DateTime.now().difference(ci).inHours >= 16;
        });
        if (hasOpen) {
          final uid = data['userId'] as String? ?? '';
          if (uid.isNotEmpty) {
            ids.add(uid);
          }
        }
      }

      if (mounted) {
        setState(() {
          _workerIdsWithOpenSession = ids;
        });
      }
    } catch (e) {
      debugPrint('ManageWorkersScreen: attendance issues query failed: $e');
    }
  }

  Future<void> _callWorker(
      BuildContext context, String name, String phone) async {
    final confirmed = await showAppDialog(
      context,
      title: 'שיחה יוצאת',
      message: 'להתקשר אל $name?\n$phone',
      confirmText: 'התקשר',
      icon: Icons.phone_rounded,
      iconGradient: const [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    );

    if (confirmed != true) return;

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('לא ניתן לחייג אל $phone')),
      );
    }
  }

  Future<void> _resolveInitialTab() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['worker', 'manager', 'co_owner'])
          .where('approved', isEqualTo: false)
          .get();
      if (!mounted) return;
      final hasPending = snap.docs.any(
        (doc) => doc.data()['rejected'] != true,
      );
      if (hasPending) {
        _tabController.animateTo(0);
      }
    } catch (e) {
      debugPrint('ManageWorkersScreen: failed to resolve initial tab: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
          const SizedBox(height: AppDimensions.spacingS),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: "עובדים חדשים"),
              Tab(text: "עובדים פעילים"),
            ],
          ),
          // Attendance issues banner
          if (_workerIdsWithOpenSession.isNotEmpty)
            _buildAttendanceBanner(),
          const SizedBox(height: AppDimensions.spacingS),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'חיפוש עובד לפי שם...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNewWorkersTab(),
                _buildApprovedWorkersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Orange banner shown when one or more workers have an unclosed session.
  Widget _buildAttendanceBanner() {
    final count = _workerIdsWithOpenSession.length;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        onTap: () {
          // Scroll to show the workers with issues — just refresh the list
          // by jumping to "עובדים פעילים" tab
          _tabController.animateTo(1);
        },
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF97316), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$count ${count == 1 ? 'עובד' : 'עובדים'} עם שעת יציאה חסרה החודש',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================= New Workers Tab =========================
  Widget _buildNewWorkersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['worker', 'manager', 'co_owner'])
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(cardHeight: 70, cardBorderRadius: 16);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("אין עובדים שממתינים לאישור"));
        }

        final allWorkers = snapshot.data!.docs
            .where((doc) =>
                (doc.data() as Map<String, dynamic>)['rejected'] != true)
            .toList();
        final newWorkers = _searchQuery.isEmpty
            ? allWorkers
            : allWorkers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name =
                    (data['fullName'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

        if (newWorkers.isEmpty) {
          return Center(
            child: Text(_searchQuery.isEmpty
                ? "אין עובדים שממתינים לאישור"
                : "לא נמצאו תוצאות"),
          );
        }

        return ListView.builder(
          padding: AppDimensions.paddingAllM,
          itemCount: newWorkers.length,
          itemBuilder: (context, index) {
            final user = newWorkers[index];
            final data = user.data() as Map<String, dynamic>;

            final fullName = data['fullName'] ?? '---';
            final phone = data['phoneNumber'] ?? '---';

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Card(
                elevation: AppDimensions.elevationM,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusXL,
                ),
                child: InkWell(
                  borderRadius: AppDimensions.borderRadiusXL,
                  onTap: () {
                    final currentRole =
                        context.read<UserProvider>().currentUser?.role ??
                            'manager';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApproveWorkerScreen(
                          userData: user,
                          currentUserRole: currentRole,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        ProfileAvatar(
                          imageUrl: data['profile_picture'],
                          radius: 28,
                          backgroundColor: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: AppTheme.bodyText.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                phone,
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_rounded,
                              color: Colors.green),
                          tooltip: 'התקשר',
                          onPressed: phone.isNotEmpty
                              ? () => _callWorker(context, fullName, phone)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ========================= Approved Workers Tab =========================
  Widget _buildApprovedWorkersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['worker', 'manager', 'co_owner', 'owner'])
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(cardHeight: 70, cardBorderRadius: 16);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("אין עובדים פעילים במערכת"));
        }

        const roleOrder = {'owner': 0, 'co_owner': 1, 'manager': 2, 'worker': 3};
        final allWorkers = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final ra = (a.data() as Map<String, dynamic>)['role'] as String? ?? 'worker';
            final rb = (b.data() as Map<String, dynamic>)['role'] as String? ?? 'worker';
            return (roleOrder[ra] ?? 3).compareTo(roleOrder[rb] ?? 3);
          });
        final workers = _searchQuery.isEmpty
            ? allWorkers
            : allWorkers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name =
                    (data['fullName'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

        if (workers.isEmpty) {
          return Center(
            child: Text(_searchQuery.isEmpty
                ? "אין עובדים פעילים במערכת"
                : "לא נמצאו תוצאות"),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadAttendanceIssues,
          child: ListView.builder(
          padding: AppDimensions.paddingAllM,
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final user = workers[index];
            final data = user.data() as Map<String, dynamic>;

            final fullName = data['fullName'] ?? '---';
            final phone = data['phoneNumber'] ?? '---';
            final uid = user.id; // document ID = Firebase Auth UID
            final role = data['role'] as String? ?? 'worker';
            final roleLabel = switch (role) {
              'owner' => 'בעלים',
              'co_owner' => 'שותף',
              'manager' => 'מנהל',
              _ => null,
            };
            final hasAttendanceIssue = _workerIdsWithOpenSession.contains(uid);

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Card(
                elevation: AppDimensions.elevationM,
                margin: const EdgeInsets.symmetric(vertical: 6),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.borderRadiusXL,
                ),
                child: Column(
                  children: [
                    // Tap → ReviewWorkerScreen
                    InkWell(
                      onTap: () {
                        final currentRole =
                            context.read<UserProvider>().currentUser?.role ??
                                'manager';
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewWorkerScreen(
                              userData: user,
                              currentUserRole: currentRole,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        color: hasAttendanceIssue
                            ? const Color(0xFFFFFBEB)
                            : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 10.0),
                        child: Row(
                          children: [
                            // Avatar (no dot — the warning row below is enough)
                            ProfileAvatar(
                              imageUrl: data['profile_picture'],
                              radius: 28,
                              backgroundColor: Colors.grey.shade300,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          fullName,
                                          style: AppTheme.bodyText.copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (roleLabel != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            roleLabel,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    phone,
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.phone_rounded,
                                  color: Colors.green),
                              tooltip: 'התקשר',
                              onPressed: phone.isNotEmpty
                                  ? () =>
                                      _callWorker(context, fullName, phone)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ── Attendance warning row — visible & tappable ──
                    if (hasAttendanceIssue)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceCorrectionScreen(
                              userId: uid,
                              userName: fullName,
                            ),
                          ),
                        ).then((_) => _loadAttendanceIssues()),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          color: const Color(0xFFF97316),
                          child: const Row(
                            children: [
                              Icon(Icons.timer_off_rounded,
                                  size: 15, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'חסר שעת יציאה — לחץ לתיקון',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.arrow_forward_ios_rounded,
                                  size: 12, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        );
      },
    );
  }
}
