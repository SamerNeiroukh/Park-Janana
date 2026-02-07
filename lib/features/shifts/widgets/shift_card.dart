import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_dimensions.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/features/shifts/screens/shift_details_screen.dart';

class ShiftCard extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;
  final WorkerService workerService;

  const ShiftCard({
    super.key,
    required this.shift,
    required this.shiftService,
    required this.workerService,
  });

  @override
  State<ShiftCard> createState() => ShiftCardState();
}

class ShiftCardState extends State<ShiftCard> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppDimensions.borderRadiusXL,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShiftDetailsScreen(
              shift: widget.shift,
              shiftService: widget.shiftService,
              workerService: widget.workerService,
            ),
          ),
        );
      },
      child: Card(
        elevation: AppDimensions.elevationL,
        shape:
            RoundedRectangleBorder(borderRadius: AppDimensions.borderRadiusXL),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildStatusIndicator(),
              const SizedBox(width: 14),
              Expanded(child: _buildMainInfo()),
              const Icon(Icons.chevron_left, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================
  // UI PARTS
  // ===============================

  Widget _buildStatusIndicator() {
    final bool isFull =
        widget.shift.assignedWorkers.length >= widget.shift.maxWorkers;
    final bool hasRequests = widget.shift.requestedWorkers.isNotEmpty;

    Color color = AppColors.primary;
    IconData icon = Icons.event_available;

    if (isFull) {
      color = AppColors.success;
      icon = Icons.check_circle;
    } else if (hasRequests) {
      color = AppColors.warningOrange;
      icon = Icons.hourglass_top;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.shift.department,
          style: AppTheme.sectionTitle,
        ),
        const SizedBox(height: 4),
        Text(
          "${widget.shift.date} | ${widget.shift.startTime} - ${widget.shift.endTime}",
          style: AppTheme.bodyText.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.people, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              "${widget.shift.assignedWorkers.length}/${widget.shift.maxWorkers} עובדים",
              style: AppTheme.bodyText,
            ),
            if (widget.shift.requestedWorkers.isNotEmpty) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "בקשות: ${widget.shift.requestedWorkers.length}",
                  style: AppTheme.bodyText.copyWith(
                    color: AppColors.warningOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
