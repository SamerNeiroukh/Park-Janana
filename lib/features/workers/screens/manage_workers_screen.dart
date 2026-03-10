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

  /// Switches to the "new workers" tab if there are any pending (non-rejected)
  /// registration requests. Otherwise stays on the "active workers" tab.
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

  /// =========================
  /// New Workers Tab
  /// =========================
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
            .where((doc) => (doc.data() as Map<String, dynamic>)['rejected'] != true)
            .toList();
        final newWorkers = _searchQuery.isEmpty
            ? allWorkers
            : allWorkers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['fullName'] ?? '').toString().toLowerCase();
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
                    final currentRole = context
                            .read<UserProvider>()
                            .currentUser
                            ?.role ??
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

  /// =========================
  /// Approved Workers Tab
  /// =========================
  Widget _buildApprovedWorkersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('role', whereIn: ['worker', 'manager', 'co_owner'])
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerLoading(cardHeight: 70, cardBorderRadius: 16);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("אין עובדים פעילים במערכת"));
        }

        final allWorkers = snapshot.data!.docs;
        final workers = _searchQuery.isEmpty
            ? allWorkers
            : allWorkers.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['fullName'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery);
              }).toList();

        if (workers.isEmpty) {
          return Center(
            child: Text(_searchQuery.isEmpty
                ? "אין עובדים פעילים במערכת"
                : "לא נמצאו תוצאות"),
          );
        }

        return ListView.builder(
          padding: AppDimensions.paddingAllM,
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final user = workers[index];
            final data = user.data() as Map<String, dynamic>;

            final fullName = data['fullName'] ?? '---';
            final phone = data['phoneNumber'] ?? '---';
            final role = data['role'] as String? ?? 'worker';
            final isManager = role == 'manager';

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
                    final currentRole = context
                            .read<UserProvider>()
                            .currentUser
                            ?.role ??
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
                              Row(
                                children: [
                                  Text(
                                    fullName,
                                    style: AppTheme.bodyText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  if (isManager) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'מנהל',
                                        style: TextStyle(
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
}
