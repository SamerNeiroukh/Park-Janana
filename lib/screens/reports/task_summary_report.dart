import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:park_janana/services/task_service.dart';
import 'package:park_janana/services/report_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/attendance/month_selector.dart';
import 'package:park_janana/services/pdf_export_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/config/departments.dart';
import 'package:flutter/services.dart';

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
  String? selectedDepartment;
  String? selectedStatus;
  DateTimeRange? selectedDateRange;

  final List<String> taskStatuses = ['pending', 'in_progress', 'done', 'cancelled'];

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    
    // Use enhanced filtering if filters are applied, otherwise use original method
    List<TaskModel> fetched;
    if (selectedDepartment != null || selectedStatus != null || selectedDateRange != null) {
      // Use enhanced filtering
      DateTime? startDate = selectedDateRange?.start ?? DateTime(selectedMonth.year, selectedMonth.month, 1);
      DateTime? endDate = selectedDateRange?.end ?? DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
      
      fetched = await ReportService.getTasksByFilters(
        department: selectedDepartment,
        status: selectedStatus,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Filter by user assignment if not filtering by department
      if (selectedDepartment == null) {
        fetched = fetched.where((task) => task.assignedTo.contains(widget.userId)).toList();
      }
    } else {
      // Use original method for backward compatibility
      fetched = await TaskService.getTasksForUserByMonth(
        widget.userId,
        selectedMonth,
      );
    }
    
    setState(() {
      tasks = fetched;
      isLoading = false;
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() {
      selectedMonth = newMonth;
      // Reset date range when month changes
      selectedDateRange = null;
    });
    _loadTasks();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: selectedDateRange ?? DateTimeRange(
        start: DateTime(selectedMonth.year, selectedMonth.month, 1),
        end: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
      ),
    );
    
    if (picked != null) {
      setState(() => selectedDateRange = picked);
      _loadTasks();
    }
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

  Future<void> _exportToExcel() async {
    if (tasks.isEmpty) return;
    
    final formattedDate = selectedDateRange != null
        ? '${DateFormat('yyyy-MM-dd').format(selectedDateRange!.start)}_to_${DateFormat('yyyy-MM-dd').format(selectedDateRange!.end)}'
        : DateFormat('yyyy-MM').format(selectedMonth);
    final fileName = 'tasks_${widget.userName}_$formattedDate.xlsx';
    
    final filePath = await ReportService.exportTasksToExcel(tasks, fileName);
    
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('הדוח נשמר בהצלחה: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Copy file path to clipboard
      Clipboard.setData(ClipboardData(text: filePath));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה בשמירת הדוח'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final pending = tasks.where((t) => t.status == 'pending').length;

    return Scaffold(
      appBar: const UserHeader(),
      body: SafeArea(
        child: Column(
          children: [
            MonthSelector(
              selectedMonth: selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            
            // Filters Card
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'מחלקה',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedDepartment,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('כל המחלקות'),
                              ),
                              ...allDepartments.map((dept) => DropdownMenuItem<String>(
                                value: dept,
                                child: Text(dept),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() => selectedDepartment = value);
                              _loadTasks();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'סטטוס',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedStatus,
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('כל הסטטוסים'),
                              ),
                              ...taskStatuses.map((status) => DropdownMenuItem<String>(
                                value: status,
                                child: Text(_getStatusText(status)),
                              )),
                            ],
                            onChanged: (value) {
                              setState(() => selectedStatus = value);
                              _loadTasks();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range),
                        label: Text(selectedDateRange != null
                            ? '${DateFormat('dd/MM/yyyy').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'
                            : 'בחר טווח תאריכים'),
                      ),
                    ),
                  ],
                ),
              ),
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
                            selectedDateRange != null
                                ? '${DateFormat('dd/MM').format(selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(selectedDateRange!.end)}'
                                : formattedMonth,
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
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'בביצוע: $inProgress',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          'ממתינות: $pending',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 14,
                            color: Colors.blue,
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
              const Expanded(child: Center(child: Text('אין משימות זמינות לפי הפילטרים שנבחרו')))
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
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(task.status),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _getStatusText(task.status),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          task.department,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('משימה: ${task.title}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('תיאור: ${task.description}'),
                                    Text('תאריך יעד: $formattedDate'),
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
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportToPdf,
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('יצוא PDF'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportToExcel,
                              icon: const Icon(Icons.file_download),
                              label: const Text('יצוא Excel'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'ממתינה';
      case 'in_progress':
        return 'בביצוע';
      case 'done':
        return 'הושלמה';
      case 'cancelled':
        return 'מבוטלת';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}