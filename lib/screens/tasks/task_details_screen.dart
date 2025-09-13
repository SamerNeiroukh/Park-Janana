import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/models/user_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/services/worker_service.dart';
import 'package:park_janana/widgets/task/task_description_section.dart';
import 'package:park_janana/widgets/task/task_comments_section.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TaskDetailsScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailsScreen({super.key, required this.task});

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();
  final TextEditingController _commentController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  List<UserModel> _assignedWorkers = [];
  bool _isWorker = false;
  late TaskModel task;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    task = widget.task;
    _fetchTaskAndWorkers();
  }

  Future<void> _fetchTaskAndWorkers() async {
    final updatedTask = await _taskService.getTaskById(widget.task.id);
    if (updatedTask != null) {
      final workers = await _workerService.getUsersByIds(updatedTask.assignedTo);
      setState(() {
        task = updatedTask;
        _assignedWorkers = workers;
        _isWorker = task.assignedTo.contains(_currentUser?.uid ?? "");
      });
    }
  }

  Future<void> _updateWorkerStatus(String newStatus) async {
    await _taskService.updateWorkerStatus(task.id, _currentUser!.uid, newStatus);
    await _fetchTaskAndWorkers();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      await _taskService.addComment(task.id, {
        'by': _currentUser!.uid,
        'message': _commentController.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      _commentController.clear();
      await _fetchTaskAndWorkers();
    } catch (e) {
      debugPrint("Failed to submit comment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("שגיאה בשליחת תגובה")),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'in_progress':
        color = Colors.orange;
        break;
      case 'done':
        color = Colors.green;
        break;
      case 'pending':
      default:
        color = Colors.grey;
    }
    return Chip(
      label: Text(_getStatusText(status)),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWorkerStatusBadge(String status) {
    Color bgColor;
    String label;
    switch (status) {
      case 'in_progress':
        bgColor = Colors.orange;
        label = 'בתהליך';
        break;
      case 'done':
        bgColor = Colors.green;
        label = 'הושלם';
        break;
      case 'pending':
      default:
        bgColor = Colors.grey;
        label = 'טרם התחיל';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bgColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bgColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return "טרם התחיל";
      case 'in_progress':
        return "בתהליך";
      case 'done':
        return "הושלם";
      default:
        return "לא ידוע";
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userId = _currentUser?.uid ?? '';
    final currentWorkerStatus = task.workerProgress[userId]?['status'] ?? 'pending';
    final String time = DateFormat('HH:mm').format(task.dueDate.toDate());
    final String dateFormatted = DateFormat('dd/MM/yyyy').format(task.dueDate.toDate());

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatusChip(task.status),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Text(task.title,
                          style: AppTheme.screenTitle.copyWith(fontSize: 24)),
                      const SizedBox(height: 16),
                      TaskDescriptionSection(
                        description: task.description,
                        time: time,
                        dateFormatted: dateFormatted,
                        isManager: false,
                        task: task,
                      ),
                      const SizedBox(height: 24),
                      Text("עובדים שהוקצו למשימה", style: AppTheme.sectionTitle),
                      const SizedBox(height: 8),
                      ..._assignedWorkers.map((user) {
                        final workerStatus = task.workerProgress[user.uid]?['status'] ?? 'pending';
                        return Card(
                          color: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(user.profilePicture),
                            ),
                            title: Text(user.fullName),
                            trailing: _buildWorkerStatusBadge(workerStatus),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      
                      // Image attachments section
                      if (task.attachments.isNotEmpty) ...[
                        Text("תמונות מצורפות", style: AppTheme.sectionTitle),
                        const SizedBox(height: 8),
                        _buildImageGallery(task.attachments),
                        const SizedBox(height: 24),
                      ],
                      
                      TaskCommentsSection(
                        taskId: task.id,
                        comments: task.comments,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        decoration: AppTheme.inputDecoration(hintText: "הוסף תגובה..."),
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
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          child: const Text("🚧 התחל משימה"),
                        ),
                      if (_isWorker && currentWorkerStatus == 'in_progress')
                        ElevatedButton(
                          onPressed: () => _updateWorkerStatus('done'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

  String _getPriorityName(String key) {
    switch (key) {
      case 'high':
        return 'גבוהה';
      case 'low':
        return 'נמוכה';
      default:
        return 'בינונית';
    }
  }

  String _getDepartmentName(String key) {
    switch (key) {
      case 'paintball':
        return 'פיינטבול';
      case 'ropes':
        return 'פארק חבלים';
      case 'carting':
        return 'קארטינג';
      case 'water_park':
        return 'פארק מים';
      case 'jimbory':
        return 'גִימבורי';
      default:
        return 'כללי';
    }
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: imageUrls.length,
      itemBuilder: (context, index) {
        return _buildImageThumbnail(imageUrls[index], index);
      },
    );
  }

  Widget _buildImageThumbnail(String imageUrl, int index) {
    return GestureDetector(
      onTap: () => _showFullImage(context, imageUrl),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error, color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
