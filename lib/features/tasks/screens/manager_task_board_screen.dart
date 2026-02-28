import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/task_model.dart';
import '../providers/task_board_provider.dart';
import '../providers/task_timeline_provider.dart';
import '../theme/task_theme.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'create_task_flow_screen.dart';

class ManagerTaskBoardScreen extends StatefulWidget {
  const ManagerTaskBoardScreen({super.key});

  @override
  State<ManagerTaskBoardScreen> createState() => _ManagerTaskBoardScreenState();
}

class _ManagerTaskBoardScreenState extends State<ManagerTaskBoardScreen>
    with SingleTickerProviderStateMixin {
  late final TaskBoardProvider _provider;
  late final TabController _tabController;
  final PageController _pageController = PageController();
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 0;
  int _tabIndex = 0;
  bool _isNavigating = false;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _provider = TaskBoardProvider();
    _uid = context.read<AppAuthProvider>().uid;
    if (_uid != null) _provider.init(_uid!);
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        setState(() => _tabIndex = _tabController.index);
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _provider.dispose();
    _pageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTopTabBar() {
    const labels = ['משימות שיצרתי', 'המשימות שלי'];
    const colors = [TaskTheme.primary, Color(0xFF8B5CF6)];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => _tabController.animateTo(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i == 1 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors[i].withOpacity(0.10)
                      : TaskTheme.surface,
                  borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                  border: Border.all(
                    color: isSelected ? colors[i] : TaskTheme.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colors[i] : TaskTheme.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: TaskTheme.background,
          floatingActionButton: _tabIndex == 0 ? _buildFab() : null,
          body: Column(
            children: [
              const Directionality(
                textDirection: TextDirection.ltr,
                child: UserHeader(),
              ),
              _buildTopTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    // ── Tab 0: Tasks I created (board) ────────────────
                    Column(
                      children: [
                        _buildHeader(),
                        _buildSearchAndFilter(),
                        _buildColumnTabs(),
                        Expanded(child: _buildBoard()),
                      ],
                    ),
                    // ── Tab 1: Tasks assigned to me ───────────────────
                    _uid != null
                        ? _MyTasksTab(uid: _uid!)
                        : const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
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
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: TaskTheme.textTertiary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
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
        final hasPendingReview = provider.hasPendingReview(task);
        return Column(
          children: [
            Dismissible(
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
            ),
            if (hasPendingReview)
              _buildApprovalStrip(task, provider),
          ],
        );
      },
    );
  }

  Widget _buildApprovalStrip(TaskModel task, TaskBoardProvider provider) {
    final workers = provider.pendingReviewWorkers(task);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withOpacity(0.10),
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top_rounded,
              size: 16, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${workers.length} עובד${workers.length == 1 ? '' : 'ים'} ממתינ${workers.length == 1 ? '' : 'ים'} לאישור',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _approveAllPendingReview(task, workers, provider),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
            ),
            child: const Text('אשר הכל'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveAllPendingReview(
    TaskModel task,
    List<String> workerIds,
    TaskBoardProvider provider,
  ) async {
    if (_uid == null) return;
    for (final workerId in workerIds) {
      await provider.approveWorker(task.id, workerId, _uid!);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('המשימה אושרה בהצלחה'),
          backgroundColor: TaskTheme.done,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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

    if (result ?? false) {
      await _provider.deleteTask(task.id);
      return true;
    }
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MY TASKS TAB  (tasks assigned to the manager — worker-style timeline)
// ─────────────────────────────────────────────────────────────────────────────

class _MyTasksTab extends StatefulWidget {
  final String uid;

  const _MyTasksTab({required this.uid});

  @override
  State<_MyTasksTab> createState() => _MyTasksTabState();
}

class _MyTasksTabState extends State<_MyTasksTab> {
  late final TaskTimelineProvider _provider;
  bool _showAllCompleted = false;

  @override
  void initState() {
    super.initState();
    _provider = TaskTimelineProvider();
    _provider.init(widget.uid);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<TaskTimelineProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: TaskTheme.primary),
            );
          }

          return RefreshIndicator(
            color: TaskTheme.primary,
            onRefresh: () async => _provider.init(widget.uid),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              children: [
                _buildSummaryCard(provider),
                const SizedBox(height: 20),

                if (provider.overdueTasks.isNotEmpty) ...[
                  _buildSection('באיחור', Icons.warning_amber_rounded,
                      TaskTheme.overdue, provider.overdueTasks, provider),
                  const SizedBox(height: 20),
                ],

                if (provider.todayTasks.isNotEmpty) ...[
                  _buildSection('להיום', Icons.today_rounded,
                      TaskTheme.pending, provider.todayTasks, provider,
                      showActions: true),
                  const SizedBox(height: 20),
                ],

                if (provider.upcomingTasks.isNotEmpty) ...[
                  _buildSection('הקרובות', Icons.event_rounded,
                      TaskTheme.inProgress, provider.upcomingTasks, provider),
                  const SizedBox(height: 20),
                ],

                if (provider.completedTasks.isNotEmpty)
                  _buildCompletedSection(provider),

                if (provider.overdueTasks.isEmpty &&
                    provider.todayTasks.isEmpty &&
                    provider.upcomingTasks.isEmpty &&
                    provider.completedTasks.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(TaskTimelineProvider provider) {
    final completed = provider.todayCompleted;
    final total = provider.todayTotal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TaskTheme.primary, TaskTheme.primaryLight],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(TaskTheme.radiusXL),
        boxShadow: [
          BoxShadow(
            color: TaskTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.task_alt_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'המשימות שלי',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'אין משימות להיום'
                      : '$completed מתוך $total הושלמו היום',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    IconData icon,
    Color color,
    List<TaskModel> tasks,
    TaskTimelineProvider provider, {
    bool showActions = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Text(title, style: TaskTheme.heading3.copyWith(color: color)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...tasks.map((task) =>
            _buildTaskWithActions(task, provider, showActions)),
      ],
    );
  }

  Widget _buildTaskWithActions(
      TaskModel task, TaskTimelineProvider provider, bool showActions) {
    final workerStatus = task.workerStatusFor(widget.uid);

    // Show action button on every non-done task, regardless of section.
    final Widget? actionWidget =
        workerStatus != 'done' ? _buildCompactAction(task, workerStatus, provider) : null;

    return TaskCard(
      task: task,
      currentUserId: widget.uid,
      actionWidget: actionWidget,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)),
      ),
    );
  }

  /// Full-width gradient action button inside the task card.
  Widget _buildCompactAction(
      TaskModel task, String workerStatus, TaskTimelineProvider provider) {
    final isStart = workerStatus == 'pending';
    final Color fromColor =
        isStart ? const Color(0xFF6366F1) : const Color(0xFF059669);
    final Color toColor =
        isStart ? const Color(0xFF818CF8) : const Color(0xFF34D399);
    final String label = isStart ? 'התחל משימה' : 'סיים משימה';
    final IconData icon =
        isStart ? Icons.play_arrow_rounded : Icons.check_circle_rounded;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [fromColor, toColor],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: fromColor.withOpacity(0.38),
            blurRadius: 14,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          splashColor: Colors.white.withOpacity(0.15),
          onTap: () => provider.updateStatus(
              task.id, isStart ? 'in_progress' : 'done'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 9),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedSection(TaskTimelineProvider provider) {
    final tasks = provider.completedTasks;
    final displayTasks =
        _showAllCompleted ? tasks : tasks.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: TaskTheme.done.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: TaskTheme.done),
            ),
            const SizedBox(width: 10),
            Text('הושלמו',
                style: TaskTheme.heading3.copyWith(color: TaskTheme.done)),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: TaskTheme.done.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TaskTheme.done,
                ),
              ),
            ),
            const Spacer(),
            if (tasks.length > 3)
              GestureDetector(
                onTap: () =>
                    setState(() => _showAllCompleted = !_showAllCompleted),
                child: Text(
                  _showAllCompleted ? 'הצג פחות' : 'הצג הכל',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: TaskTheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...displayTasks.map((task) => TaskCard(
              task: task,
              compact: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailsScreen(task: task),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: TaskTheme.primary.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 56,
                color: TaskTheme.primary.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'אין משימות כרגע',
              style:
                  TaskTheme.heading3.copyWith(color: TaskTheme.textTertiary),
            ),
            const SizedBox(height: 8),
            const Text('משימות חדשות יופיעו כאן', style: TaskTheme.body),
          ],
        ),
      ),
    );
  }
}
