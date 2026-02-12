import 'package:flutter/material.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';

class WorkerRow extends StatelessWidget {
  final UserModel worker;
  final String shiftId;
  final bool isAssigned;
  final WorkerService workerService;
  final bool isApproved;
  final Function(bool) onApproveToggle;
  final bool showRemoveIcon;

  const WorkerRow({
    super.key,
    required this.worker,
    required this.shiftId,
    required this.isAssigned,
    required this.workerService,
    required this.isApproved,
    required this.onApproveToggle,
    required this.showRemoveIcon,
    required Null Function() onTap, // kept as-is (not image-related)
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ProfileAvatar(
        imageUrl: worker.profilePicture,
        radius: 25.0,
      ),
      title: Text(
        worker.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
