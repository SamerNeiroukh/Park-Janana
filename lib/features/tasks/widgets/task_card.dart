import 'package:flutter/material.dart';
import 'package:park_janana/core/models/user_model.dart';
import '../models/task_model.dart';
import '../theme/task_theme.dart';
import 'task_status_badge.dart';
import 'task_priority_indicator.dart';
import 'worker_avatar_stack.dart';
import 'task_deadline_text.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final List<UserModel> assignedWorkers;
  final VoidCallback? onTap;
  final bool compact;
  final String? currentUserId;

  const TaskCard({
    super.key,
    required this.task,
    this.assignedWorkers = const [],
    this.onTap,
    this.compact = false,
    this.currentUserId,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _priorityBorderColor =>
      TaskTheme.priorityColor(widget.task.priority);

  bool get _isOverdue => widget.task.isOverdue;

  @override
  Widget build(BuildContext context) {
    if (widget.compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    final task = widget.task;
    final progress = task.completionRatio;
    final borderColor = _isOverdue ? TaskTheme.overdue : _priorityBorderColor;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: TaskTheme.surface,
            borderRadius: BorderRadius.circular(TaskTheme.radiusL),
            boxShadow: TaskTheme.cardShadow,
            border: Border(
              right: BorderSide(
                color: borderColor,
                width: 4,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: priority + status + department
                Row(
                  children: [
                    TaskPriorityIndicator(priority: task.priority),
                    const SizedBox(width: 8),
                    TaskStatusBadge(status: task.status),
                    const Spacer(),
                    if (task.department != 'general')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: TaskTheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          TaskTheme.departmentLabel(task.department),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: TaskTheme.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  task.title,
                  style: TaskTheme.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: TaskTheme.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),

                // Workers progress bar
                if (task.totalWorkerCount > 1) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: TaskTheme.border.withOpacity(0.5),
                            valueColor: AlwaysStoppedAnimation(
                              progress >= 1
                                  ? TaskTheme.done
                                  : TaskTheme.inProgress,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (progress >= 1 ? TaskTheme.done : TaskTheme.inProgress).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${task.completedWorkerCount}/${task.totalWorkerCount}',
                          style: TaskTheme.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: progress >= 1 ? TaskTheme.done : TaskTheme.inProgress,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Bottom row: avatars + deadline
                Row(
                  children: [
                    if (widget.assignedWorkers.isNotEmpty)
                      WorkerAvatarStack(workers: widget.assignedWorkers),
                    const Spacer(),
                    TaskDeadlineText(dueDate: task.dueDate.toDate()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact() {
    final task = widget.task;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: TaskTheme.doneBg.withOpacity(0.5),
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          border: Border.all(color: TaskTheme.done.withOpacity(0.2)),
          boxShadow: TaskTheme.softShadow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: TaskTheme.done,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: TaskTheme.body.copyWith(
                  color: TaskTheme.textSecondary,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: TaskTheme.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TaskDeadlineText(
              dueDate: task.dueDate.toDate(),
              showIcon: false,
              fontSize: 11,
            ),
          ],
        ),
      ),
    );
  }
}
