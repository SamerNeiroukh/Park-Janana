import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/screens/workers_management/review_worker_screen.dart';
import 'package:park_janana/screens/workers_management/approve_worker_screen.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/utils/profile_image_provider.dart';

class ManageWorkersScreen extends StatefulWidget {
  const ManageWorkersScreen({super.key});

  @override
  State<ManageWorkersScreen> createState() => _ManageWorkersScreenState();
}

class _ManageWorkersScreenState extends State<ManageWorkersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('approved', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("אין עובדים שממתינים לאישור"));
        }

        final newWorkers = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: newWorkers.length,
          itemBuilder: (context, index) {
            final user = newWorkers[index];
            final data = user.data() as Map<String, dynamic>;

            final fullName = data['fullName'] ?? '---';
            final phone = data['phoneNumber'] ?? '---';

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApproveWorkerScreen(userData: user),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        FutureBuilder<ImageProvider>(
                          future: ProfileImageProvider.resolve(
                            storagePath: data['profile_picture_path'],
                            fallbackUrl: data['profile_picture'],
                          ),
                          builder: (context, snapshot) {
                            return CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: snapshot.data,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Column(
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
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .where('approved', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("אין עובדים פעילים במערכת"));
        }

        final workers = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: workers.length,
          itemBuilder: (context, index) {
            final user = workers[index];
            final data = user.data() as Map<String, dynamic>;

            final fullName = data['fullName'] ?? '---';
            final phone = data['phoneNumber'] ?? '---';

            return Directionality(
              textDirection: TextDirection.rtl,
              child: Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewWorkerScreen(userData: user),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        FutureBuilder<ImageProvider>(
                          future: ProfileImageProvider.resolve(
                            storagePath: data['profile_picture_path'],
                            fallbackUrl: data['profile_picture'],
                          ),
                          builder: (context, snapshot) {
                            return CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: snapshot.data,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Column(
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
