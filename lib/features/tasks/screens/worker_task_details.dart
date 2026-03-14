import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_theme.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/services/task_service.dart';
import 'package:park_janana/features/tasks/widgets/task_description_section.dart';
import 'package:park_janana/features/tasks/widgets/task_comments_section.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:intl/intl.dart' hide TextDirection;

class WorkerTaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const WorkerTaskDetailsScreen({super.key, required this.task});

  @override
  State<WorkerTaskDetailsScreen> createState() =>
      _WorkerTaskDetailsScreenState();
}

// ── Attachment display widget ──────────────────────────────────────────────

class _AttachmentsSection extends StatelessWidget {
  final List<String> attachments;
  const _AttachmentsSection({required this.attachments});

  IconData _iconFor(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return Icons.image_rounded;
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) {
      return Icons.videocam_rounded;
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
      return Icons.description_rounded;
    }
    return Icons.attach_file_rounded;
  }

  String _labelFor(String url) {
    try {
      final name = Uri.parse(url).pathSegments.last;
      return Uri.decodeComponent(name).split('?').first;
    } catch (_) {
      return 'קובץ מצורף';
    }
  }

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('לא ניתן לפתוח את הקובץ')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'קבצים מצורפים',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          ...attachments.map((url) => _AttachmentTile(
                label: _labelFor(url),
                icon: _iconFor(url),
                onTap: () => _open(context, url),
              )),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _AttachmentTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        dense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4F46E5)),
        ),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        trailing: const Icon(Icons.open_in_new_rounded,
            size: 16, color: Color(0xFF9CA3AF)),
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _WorkerTaskDetailsScreenState extends State<WorkerTaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final TextEditingController _commentController = TextEditingController();

  bool _isWorker = false;
  late TaskModel task;
  bool _isSubmitting = false;

  String? get _currentUid => context.read<AppAuthProvider>().uid;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    task = widget.task;
    _fetchTaskAndWorkers();
  }

  Future<void> _fetchTaskAndWorkers() async {
    final updatedTask = await _taskService.getTaskById(widget.task.id);
    if (updatedTask != null) {
      setState(() {
        task = updatedTask;
        _isWorker = task.assignedTo.contains(_currentUid ?? "");
      });
    }
  }

  Future<void> _updateWorkerStatus(String newStatus) async {
    if (_currentUid == null) return;
    await _taskService.updateWorkerStatus(task.id, _currentUid!, newStatus);
    await _fetchTaskAndWorkers();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _isSubmitting || _currentUid == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _taskService.addComment(task.id, {
        'by': _currentUid,
        'message': _commentController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentController.clear();
      await _fetchTaskAndWorkers();
    } catch (e) {
      debugPrint("Failed to submit comment: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("שגיאה בשליחת תגובה")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _currentUid ?? '';
    final currentWorkerStatus =
        task.workerProgress[userId]?['status'] ?? 'pending';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const UserHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchTaskAndWorkers,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(task.title,
                          style: AppTheme.screenTitle.copyWith(fontSize: 24)),
                      const SizedBox(height: 16),
                      TaskDescriptionSection(
                        description: task.description,
                        time: DateFormat('HH:mm').format(task.dueDate.toDate()),
                        dateFormatted: DateFormat('dd/MM/yyyy')
                            .format(task.dueDate.toDate()),
                        isManager: false,
                        task: task,
                      ),
                      if (task.attachments.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _AttachmentsSection(attachments: task.attachments),
                      ],
                      const SizedBox(height: 24),
                      TaskCommentsSection(
                        comments: task.comments,
                        taskId: task.id,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration:
                            AppTheme.inputDecoration(hintText: "הוסף תגובה..."),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _addComment,
                        style: AppTheme.primaryButtonStyle,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("💬 שלח תגובה"),
                      ),
                      const SizedBox(height: 32),
                      if (_isWorker && currentWorkerStatus == 'pending')
                        ElevatedButton(
                          onPressed: () => _updateWorkerStatus('in_progress'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange),
                          child: const Text("🚧 התחל משימה"),
                        ),
                      if (_isWorker && currentWorkerStatus == 'in_progress')
                        ElevatedButton(
                          onPressed: () => _updateWorkerStatus('done'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green),
                          child: const Text("✅ סיים משימה"),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
