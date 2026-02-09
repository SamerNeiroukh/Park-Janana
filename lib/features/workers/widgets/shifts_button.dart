import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/constants/app_durations.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';

class ShiftsButtonScreen extends StatefulWidget {
  final String uid;
  final String fullName;
  final String profilePicture; // legacy URL support
  final String? profilePicturePath; // Firebase Storage path

  const ShiftsButtonScreen({
    super.key,
    required this.uid,
    required this.fullName,
    required this.profilePicture,
    this.profilePicturePath,
  });

  @override
  State<ShiftsButtonScreen> createState() => _ShiftsButtonScreenState();
}

class _ShiftsButtonScreenState extends State<ShiftsButtonScreen>
    with SingleTickerProviderStateMixin {
  String filter = 'all';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppDurations.slow,
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlueLight,
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildWorkerSummary(),
                  const SizedBox(height: AppDimensions.spacingXL),
                  _buildFilterButtons(),
                  const SizedBox(height: AppDimensions.spacingXL),
                  Expanded(child: _buildShiftList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSummary() {
    return FadeTransition(
      opacity: _animationController,
      child: Container(
        padding: AppDimensions.paddingAllL,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.borderRadiusXL,
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: AppDimensions.elevationXL,
              offset: AppDimensions.shadowOffsetS,
            ),
          ],
        ),
        child: Row(
          children: [
            ProfileAvatar(
              storagePath: widget.profilePicturePath,
              fallbackUrl: widget.profilePicture,
              radius: AppDimensions.avatarS * 0.75,
              backgroundColor: AppColors.greyLight,
            ),
            const SizedBox(width: AppDimensions.spacingXL),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.fullName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: AppDimensions.fontXXL,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  const Text(
                    "רשימת המשמרות של העובד",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: AppDimensions.fontM,
                      color: AppColors.greyDark,
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

  Widget _buildFilterButtons() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _filterButton("all", "הכל"),
          _filterButton("upcoming", "קרובות"),
          _filterButton("past", "עבר"),
          _filterButton("today", "היום"),
          _filterButton("thisWeek", "השבוע"),
        ],
      ),
    );
  }

  Widget _filterButton(String value, String label) {
    final isSelected = filter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingXS),
      child: ElevatedButton(
        onPressed: () => setState(() => filter = value),
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? AppColors.primary : AppColors.greyLight,
          foregroundColor:
              isSelected ? AppColors.textWhite : AppColors.textPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: AppDimensions.borderRadiusXXL),
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingS),
        ),
        child: Text(
          label,
          style: const TextStyle(
              fontSize: AppDimensions.fontS, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildShiftList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.shiftsCollection)
          .where('assignedWorkers', arrayContains: widget.uid)
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(
              child: Text("לא ניתן לטעון נתונים. בדוק חיבור או אינדקס."));
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("אין משמרות להצגה"));
        }

        final now = DateTime.now();
        final allShifts = snapshot.data!.docs;

        final filtered = allShifts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final rawDate = data['date'];
          DateTime? date;

          if (rawDate is Timestamp) {
            date = rawDate.toDate();
          } else if (rawDate is String) {
            try {
              date = DateFormat('dd/MM/yyyy').parseStrict(rawDate);
            } catch (_) {
              return false;
            }
          }

          if (date == null) return false;

          switch (filter) {
            case 'upcoming':
              return date.isAfter(now);
            case 'past':
              return date.isBefore(now);
            case 'today':
              return date.day == now.day &&
                  date.month == now.month &&
                  date.year == now.year;
            case 'thisWeek':
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              final weekEnd = weekStart.add(const Duration(days: 6));
              return date
                      .isAfter(weekStart.subtract(const Duration(days: 1))) &&
                  date.isBefore(weekEnd.add(const Duration(days: 1)));
            default:
              return true;
          }
        }).toList();

        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final shift = filtered[index].data() as Map<String, dynamic>;
            final rawDate = shift['date'];
            DateTime? date;

            if (rawDate is Timestamp) {
              date = rawDate.toDate();
            } else if (rawDate is String) {
              try {
                date = DateFormat('dd/MM/yyyy').parseStrict(rawDate);
              } catch (_) {}
            }

            final startTime = shift['startTime'] ?? "--";
            final endTime = shift['endTime'] ?? "--";
            final department = shift['department'] ?? "--";
            final note = shift['notes']?[widget.uid] ?? '';

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppDimensions.spacingL),
                padding: const EdgeInsets.all(AppDimensions.paddingML),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimensions.borderRadiusML,
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: AppDimensions.elevationXL,
                      offset: AppDimensions.shadowOffsetS,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          date != null
                              ? DateFormat('dd/MM/yyyy').format(date)
                              : "--",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: AppDimensions.fontL),
                        ),
                        const SizedBox(width: AppDimensions.spacingM),
                        const Icon(Icons.calendar_today,
                            size: AppDimensions.iconS,
                            color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text("שעות: $startTime - $endTime",
                        style: AppTheme.bodyText),
                    Text("מחלקה: $department", style: AppTheme.bodyText),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        "הערה: $note",
                        style: AppTheme.bodyText
                            .copyWith(fontStyle: FontStyle.italic),
                      ),
                    ]
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
