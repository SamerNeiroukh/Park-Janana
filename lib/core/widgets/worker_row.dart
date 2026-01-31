import 'package:flutter/material.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/core/utils/profile_image_provider.dart';

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
      leading: FutureBuilder<ImageProvider>(
        future: ProfileImageProvider.resolve(
          storagePath: worker.profilePicturePath,
          fallbackUrl: worker.profilePicture,
        ),
        builder: (context, snapshot) {
          return CircleAvatar(
            radius: 25.0,
            backgroundImage: snapshot.data,
          );
        },
      ),
      title: Text(
        worker.fullName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
