import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/attendance/month_selector.dart';
import 'package:park_janana/services/pdf_export_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:park_janana/constants/app_theme.dart';

class TaskSummaryReport extends StatefulWidget {
  final String userId;
  final String userName;
  final String profileUrl;

  const TaskSummaryReport({
    super.key,
    required this.userId,
    required this.userName,
    required this.profileUrl,
  });

  @override
  State<TaskSummaryReport> createState() => _TaskSummaryReportState();
}

class _TaskSummaryReportState extends State<TaskSummaryReport> {
  late DateTime selectedMonth;
  bool isLoading = true;
  List<TaskModel> tasks = [];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    final List<TaskModel> fetched = await TaskService.getTasksForUserByMonth(
      widget.userId,
      selectedMonth,
    );
    setState(() {
      tasks = fetched;
      isLoading = false;
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() => selectedMonth = newMonth);
    _loadTasks();
  }

  void _exportToPdf() async {
    if (tasks.isEmpty) return;
    await PdfExportService.exportTaskReportPdf(
      context: context,
      userName: widget.userName,
      profileUrl: widget.profileUrl,
      tasks: tasks,
      month: selectedMonth,
      userId: widget.userId,
    );
  }

  ImageProvider _getProfileImage(String url) {
    return (url.isNotEmpty && url.startsWith('http'))
        ? CachedNetworkImageProvider(url)
        : const AssetImage('assets/images/default_profile.png');
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd/MM/yyyy HH:mm').format(ts.toDate());
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final formattedMonth = DateFormat.yMMMM('he').format(selectedMonth);
    final completed = tasks.where((t) => t.status == 'done').length;

    return Scaffold(
      appBar: const UserHeader(),
      body: SafeArea(
        child: Column(
          children: [
            MonthSelector(
              selectedMonth: selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: _getProfileImage(widget.profileUrl),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedMonth,
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'סה״כ משימות: ${tasks.length}',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'הושלמו: $completed',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (tasks.isEmpty)
              const Expanded(child: Center(child: Text('אין משימות זמינות לחודש זה')))
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final dueDate = task.dueDate is Timestamp
                                ? (task.dueDate).toDate()
                                : task.dueDate as DateTime;
                            final formattedDate = DateFormat('dd/MM/yyyy').format(dueDate);
                            final entry = task.workerProgress[widget.userId] ?? {};

                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('משימה: ${task.title}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('תיאור: ${task.description}'),
                                    Text('תאריך יעד: $formattedDate'),
                                    Text('סטטוס כללי: ${task.status}'),
                                    const SizedBox(height: 6),
                                    Text('סטטוס עובד: ${entry['status'] ?? 'unknown'}'),
                                    Text('הוגשה ב: ${_formatTimestamp(entry['submittedAt'])}'),
                                    Text('התחילה ב: ${_formatTimestamp(entry['startedAt'])}'),
                                    Text('הסתיימה ב: ${_formatTimestamp(entry['endedAt'])}'),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _exportToPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('צור קובץ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}