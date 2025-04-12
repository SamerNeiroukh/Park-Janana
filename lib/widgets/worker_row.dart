import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/worker_service.dart';

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
    required this.showRemoveIcon, required Null Function() onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isValidNetworkImage = worker.profilePicture.isNotEmpty && worker.profilePicture.startsWith('http');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 25.0,
        backgroundImage: isValidNetworkImage
            ? NetworkImage(worker.profilePicture) // ✅ Uses Firestore URL
            : const AssetImage('assets/images/default_profile.png') as ImageProvider, // ✅ Uses default if missing
        onBackgroundImageError: (_, __) {}, // ✅ Prevents red error UI on broken image
      ),
      title: Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
