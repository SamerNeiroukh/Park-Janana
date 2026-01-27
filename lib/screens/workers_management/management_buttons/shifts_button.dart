import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/utils/profile_image_provider.dart';

class ShiftsButtonScreen extends StatefulWidget {
  final String uid;
  final String fullName;
  final String profilePicture; // legacy URL support

  const ShiftsButtonScreen({
    super.key,
    required this.uid,
    required this.fullName,
    required this.profilePicture,
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
      duration: const Duration(milliseconds: 800),
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
      backgroundColor: const Color(0xFFF2F6FF),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildWorkerSummary(),
                  const SizedBox(height: 16),
                  _buildFilterButtons(),
                  const SizedBox(height: 16),
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            FutureBuilder<ImageProvider>(
              future: ProfileImageProvider.resolve(
                storagePath: 'profile_pictures/${widget.uid}/profile.jpg',
                fallbackUrl: widget.profilePicture,
              ),
              builder: (context, snapshot) {
                return CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: snapshot.data,
                );
              },
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    widget.fullName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "רשימת המשמרות של העובד",
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => setState(() => filter = value),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.primary : Colors.grey.shade300,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildShiftList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('shifts')
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
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 4),
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
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.calendar_today,
                            size: 18, color: AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text("שעות: $startTime - $endTime",
                        style: AppTheme.bodyText),
                    Text("מחלקה: $department", style: AppTheme.bodyText),
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 4),
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
