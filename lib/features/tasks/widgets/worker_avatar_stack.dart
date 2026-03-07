import 'package:flutter/material.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import '../theme/task_theme.dart';

class WorkerAvatarStack extends StatelessWidget {
  final List<UserModel> workers;
  final int maxDisplay;
  final double radius;

  const WorkerAvatarStack({
    super.key,
    required this.workers,
    this.maxDisplay = 3,
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();

    final displayed = workers.take(maxDisplay).toList();
    final overflow = workers.length - maxDisplay;
    final itemWidth = radius * 1.4;

    return SizedBox(
      height: radius * 2 + 2,
      width: (displayed.length * itemWidth) +
          (overflow > 0 ? itemWidth : 0) +
          radius * 0.6,
      child: Stack(
        children: [
          for (int i = 0; i < displayed.length; i++)
            Positioned(
              right: i * itemWidth,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ProfileAvatar(
                  imageUrl: displayed[i].profilePicture,
                  radius: radius,
                  backgroundColor: TaskTheme.primary.withOpacity(0.1),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              right: displayed.length * itemWidth,
              child: Container(
                width: radius * 2,
                height: radius * 2,
                decoration: BoxDecoration(
                  color: TaskTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$overflow',
                    style: TextStyle(
                      fontSize: radius * 0.7,
                      fontWeight: FontWeight.w700,
                      color: TaskTheme.primary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
