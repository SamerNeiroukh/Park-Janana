import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_dimensions.dart';
import 'package:park_janana/constants/app_durations.dart';
import 'package:park_janana/screens/reports/attendance_summary_report.dart';
import 'package:park_janana/screens/reports/task_summary_report.dart';
import 'package:park_janana/screens/reports/worker_shift_report.dart';
import 'package:park_janana/widgets/user_header.dart';

class WorkerReportsScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const WorkerReportsScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserHeader(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'הדוחות שלי',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const Divider(thickness: 1),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(20),
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                childAspectRatio: 1,
                children: [
                  _ReportCard(
                    icon: Icons.access_time,
                    label: 'דו״ח נוכחות',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceSummaryScreen(
                            userId: userId,
                            userName: userName,
                            profileUrl: profileUrl,
                          ),
                        ),
                      );
                    },
                    gradient: LinearGradient(
                      colors: [AppColors.lightBlue, AppColors.deepBlue],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  _ReportCard(
                    icon: Icons.task_alt_rounded,
                    label: 'דו״ח משימות',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskSummaryReport(
                            userId: userId,
                            userName: userName,
                            profileUrl: profileUrl,
                          ),
                        ),
                      );
                    },
                    gradient: LinearGradient(
                      colors: [AppColors.redLight, AppColors.redDark],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                  ),
                  _ReportCard(
                    icon: Icons.schedule_rounded,
                    label: 'דו״ח משמרות',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkerShiftReport(
                            uid: userId,
                            fullName: userName,
                            profilePicture: profileUrl,
                          ),
                        ),
                      );
                    },
                    gradient: LinearGradient(
                      colors: [AppColors.greenMedium, AppColors.darkGreen],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
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
}

class _ReportCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Gradient gradient;

  const _ReportCard({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.gradient,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.instant,
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    )..forward();
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(_) => _controller.reverse();
  void _handleTapUp(_) => _controller.forward();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: () => _controller.forward(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: AppDimensions.borderRadiusXXL,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: AppDimensions.paddingAllXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: AppDimensions.iconLarge, color: Colors.white),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
