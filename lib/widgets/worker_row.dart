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
  final bool showRemoveIcon; // ✅ Control remove icon

  const WorkerRow({
    super.key,
    required this.worker,
    required this.shiftId,
    required this.isAssigned,
    required this.workerService,
    required this.isApproved,
    required this.onApproveToggle,
    required this.showRemoveIcon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 25.0,
        backgroundImage: worker.profilePicture.startsWith('http')
            ? NetworkImage(worker.profilePicture)
            : const AssetImage('assets/images/default_profile.png') as ImageProvider,
      ),
      title: Text(worker.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: showRemoveIcon // ✅ Only show if true
          ? IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () async {
                await workerService.removeWorker(shiftId, worker.uid);
              },
            )
          : IconButton(
              icon: Icon(
                isApproved ? Icons.remove_circle : Icons.check_circle,
                color: isApproved ? Colors.red : Colors.green,
              ),
              onPressed: () => onApproveToggle(!isApproved),
            ),
    );
  }
}
