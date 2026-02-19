import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/task_model.dart';
import '../providers/task_board_provider.dart';
import '../theme/task_theme.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'create_task_flow_screen.dart';

class ManagerTaskBoardScreen extends StatefulWidget {
  const ManagerTaskBoardScreen({super.key});

  @override
  State<ManagerTaskBoardScreen> createState() => _ManagerTaskBoardScreenState();
}

class _ManagerTaskBoardScreenState extends State<ManagerTaskBoardScreen> {
  late final TaskBoardProvider _provider;
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _provider = TaskBoardProvider();
    final uid = context.read<AppAuthProvider>().uid;
    if (uid != null) _provider.init(uid);
  }

  @override
  void dispose() {
    _provider.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: TaskTheme.background,
          floatingActionButton: _buildFab(),
          body: Column(
            children: [
              const Directionality(
                textDirection: TextDirection.ltr,
                child: UserHeader(),
              ),
              _buildHeader(),
              _buildSearchAndFilter(),
              _buildColumnTabs(),
              Expanded(child: _buildBoard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      backgroundColor: TaskTheme.primary,
      elevation: 6,
      onPressed: () async {
        if (_isNavigating) return;
        _isNavigating = true;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskFlowScreen()),
        );
        if (mounted) _isNavigating = false;
      },
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
    );
  }

  Widget _buildHeader() {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ניהול משימות', style: TaskTheme.heading1),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.totalCount} משימות • ${provider.overdueCount} באיחור',
                      style: TaskTheme.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter() {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: TaskTheme.surface,
                    borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                    border: Border.all(color: TaskTheme.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: provider.setSearch,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'חיפוש משימה...',
                      hintStyle: TaskTheme.body,
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 20, color: TaskTheme.textTertiary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  size: 18, color: TaskTheme.textTertiary),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildDepartmentDropdown(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDepartmentDropdown(TaskBoardProvider provider) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        border: Border.all(color: TaskTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: provider.departmentFilter,
          icon: const Icon(Icons.filter_list_rounded,
              size: 18, color: TaskTheme.textSecondary),
          style: TaskTheme.body.copyWith(color: TaskTheme.textPrimary),
          onChanged: provider.setDepartmentFilter,
          items: [
            const DropdownMenuItem(value: null, child: Text('הכל')),
            ...['general', 'paintball', 'ropes', 'carting', 'water_park', 'jimbory']
                .map((d) => DropdownMenuItem(
                    value: d, child: Text(TaskTheme.departmentLabel(d)))),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnTabs() {
    final columns = [
      {'label': 'ממתין', 'status': 'pending', 'color': TaskTheme.pending},
      {'label': 'בביצוע', 'status': 'in_progress', 'color': TaskTheme.inProgress},
      {'label': 'הושלם', 'status': 'done', 'color': TaskTheme.done},
    ];

    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        final counts = [
          provider.pendingTasks.length,
          provider.inProgressTasks.length,
          provider.doneTasks.length,
        ];

        return Container(
          margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: List.generate(3, (i) {
              final isActive = _currentPage == i;
              final color = columns[i]['color'] as Color;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                        left: i > 0 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? color.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                      border: Border.all(
                        color: isActive ? color : TaskTheme.border,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          columns[i]['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? color : TaskTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? color : TaskTheme.textTertiary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${counts[i]}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildBoard() {
    return Consumer<TaskBoardProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: TaskTheme.primary),
          );
        }

        final columns = [
          provider.pendingTasks,
          provider.inProgressTasks,
          provider.doneTasks,
        ];

        return PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemCount: 3,
          itemBuilder: (context, columnIndex) {
            return _buildColumn(columns[columnIndex], provider);
          },
        );
      },
    );
  }

  Widget _buildColumn(List<TaskModel> tasks, TaskBoardProvider provider) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: TaskTheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 48,
                color: TaskTheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'אין משימות',
              style: TaskTheme.heading3.copyWith(color: TaskTheme.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (_) => _confirmDelete(task),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: TaskTheme.overdue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(TaskTheme.radiusL),
            ),
            child: const Icon(Icons.delete_outline_rounded,
                color: TaskTheme.overdue, size: 24),
          ),
          child: TaskCard(
            task: task,
            assignedWorkers: provider.workersForTask(task),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TaskDetailsScreen(task: task),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(TaskModel task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('מחיקת משימה'),
          content: Text('למחוק את "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('מחק',
                  style: TextStyle(color: TaskTheme.overdue)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await _provider.deleteTask(task.id);
      return true;
    }
    return false;
  }
}
