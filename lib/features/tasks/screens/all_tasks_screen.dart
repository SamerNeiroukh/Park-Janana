import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/screens/task_details_screen.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class AllTasksScreen extends StatefulWidget {
  const AllTasksScreen({super.key});

  @override
  State<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends State<AllTasksScreen> {
  // null = show all
  String? _statusFilter;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static const _filters = [
    _Filter(label: 'הכל', value: null, color: Color(0xFF7C3AED)),
    _Filter(label: 'ממתין', value: 'pending', color: TaskTheme.pending),
    _Filter(label: 'בביצוע', value: 'in_progress', color: TaskTheme.inProgress),
    _Filter(label: 'הושלם', value: 'done', color: TaskTheme.done),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TaskTheme.background,
      appBar: const UserHeader(),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterRow(),
            _buildSearchBar(),
            const SizedBox(height: 4),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: TaskTheme.buttonShadow(const Color(0xFF7C3AED)),
            ),
            child: const Icon(Icons.assignment_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'כל המשימות',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: TaskTheme.textPrimary,
                ),
              ),
              Text(
                'תצוגה כוללת לכל המשימות',
                style: TextStyle(
                    fontSize: 12, color: TaskTheme.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isSelected = _statusFilter == f.value;
          return GestureDetector(
            onTap: () => setState(() => _statusFilter = f.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? f.color : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? f.color : const Color(0xFFE2E8F0),
                ),
                boxShadow: isSelected ? TaskTheme.softShadow : [],
              ),
              child: Text(
                f.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : TaskTheme.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: TextField(
        controller: _searchCtrl,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          hintText: 'חיפוש משימה...',
          hintStyle: const TextStyle(
              color: TaskTheme.textTertiary, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: TaskTheme.textTertiary, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close_rounded,
                      color: TaskTheme.textTertiary, size: 18),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
                color: Color(0xFF7C3AED), width: 1.5),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
      ),
    );
  }

  Widget _buildTaskList() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection(AppConstants.tasksCollection);

    if (_statusFilter != null) {
      query = query.where('status', isEqualTo: _statusFilter);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text('שגיאה: ${snap.error}',
                style: const TextStyle(color: Colors.red)),
          );
        }

        var tasks = snap.data?.docs
                .map((d) => TaskModel.fromFirestore(d))
                .toList() ??
            [];

        // Client-side search filter
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          tasks = tasks
              .where((t) =>
                  t.title.toLowerCase().contains(q) ||
                  t.description.toLowerCase().contains(q))
              .toList();
        }

        // Sort: overdue first, then by dueDate ascending
        tasks.sort((a, b) {
          if (a.isOverdue && !b.isOverdue) return -1;
          if (!a.isOverdue && b.isOverdue) return 1;
          if (a.status == 'done' && b.status != 'done') return 1;
          if (a.status != 'done' && b.status == 'done') return -1;
          return a.dueDate.compareTo(b.dueDate);
        });

        if (tasks.isEmpty) {
          return _buildEmpty();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _TaskRow(
            task: tasks[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TaskDetailsScreen(task: tasks[i])),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    final label = _statusFilter == null
        ? 'אין משימות'
        : 'אין משימות ${TaskTheme.statusLabel(_statusFilter!)}';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt_rounded,
              size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(label,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TaskTheme.textSecondary)),
        ],
      ),
    );
  }
}

// ── Filter descriptor ──────────────────────────────────────────────────────

class _Filter {
  final String label;
  final String? value;
  final Color color;
  const _Filter(
      {required this.label, required this.value, required this.color});
}

// ── Task row card ──────────────────────────────────────────────────────────

class _TaskRow extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const _TaskRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priorityColor = TaskTheme.priorityColor(task.priority);
    final statusColor = TaskTheme.statusColor(task.status);
    final statusBg = TaskTheme.statusBgColor(task.status);
    final dueDate = task.dueDate.toDate();
    final dueDateStr = DateFormat('d/M/yyyy').format(dueDate);
    final isOverdue = task.isOverdue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: TaskTheme.cardShadow,
          border: isOverdue
              ? Border.all(color: TaskTheme.overdue.withOpacity(0.4))
              : null,
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Priority stripe
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + status badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: TaskTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              TaskTheme.statusLabel(task.status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: TaskTheme.textTertiary,
                            height: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Meta row
                      Row(
                        children: [
                          // Due date
                          Icon(
                            isOverdue
                                ? Icons.warning_amber_rounded
                                : Icons.calendar_today_rounded,
                            size: 13,
                            color: isOverdue
                                ? TaskTheme.overdue
                                : TaskTheme.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dueDateStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: isOverdue
                                  ? TaskTheme.overdue
                                  : TaskTheme.textTertiary,
                              fontWeight: isOverdue
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Priority badge
                          Icon(TaskTheme.priorityIcon(task.priority),
                              size: 13, color: priorityColor),
                          const SizedBox(width: 4),
                          Text(
                            TaskTheme.priorityLabel(task.priority),
                            style: TextStyle(
                              fontSize: 12,
                              color: priorityColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          // Worker count
                          if (task.assignedTo.isNotEmpty) ...[
                            const Icon(Icons.person_rounded,
                                size: 13,
                                color: TaskTheme.textTertiary),
                            const SizedBox(width: 3),
                            Text(
                              '${task.assignedTo.length}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: TaskTheme.textTertiary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(Icons.chevron_right_rounded,
                    color: TaskTheme.textTertiary, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
