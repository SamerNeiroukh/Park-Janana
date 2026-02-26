import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

const _kPrefsKey = 'notif_last_visited_ms';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  static const int _pageSize = 10;
  static const int _fetchSize = 30;

  // All fetched items, sorted newest-first
  final List<_ActivityItem> _allItems = [];
  // How many to currently display
  int _displayCount = 0;

  // Posts are cursor-paginated (ordered collection → clean startAfterDocument)
  DocumentSnapshot? _lastPostDoc;
  bool _postsDone = false;

  // Shifts + tasks loaded once (arrayContains can't orderBy without composite index)
  bool _othersDone = false;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _uid;
  String? _role;
  String? _error;

  // Timestamp of the previous visit — items newer than this are "new"
  DateTime _lastVisited = DateTime(2000);

  final ScrollController _scrollController = ScrollController();

  // True while there are more items to show or fetch
  bool get _hasMore =>
      _displayCount < _allItems.length || !_postsDone;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll listener ───────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  // ── Init ──────────────────────────────────────────────────────────────

  Future<void> _initialize() async {
    if (!mounted) return;
    _uid = context.read<AppAuthProvider>().user?.uid;
    _role = context.read<UserProvider>().currentUser?.role ?? '';

    // Load previous visit timestamp, then immediately save "now" so items
    // shown this visit won't be highlighted as new next time.
    final prefs = await SharedPreferences.getInstance();
    final prevMs = prefs.getInt(_kPrefsKey);
    if (prevMs != null) {
      _lastVisited = DateTime.fromMillisecondsSinceEpoch(prevMs);
    }
    await prefs.setInt(
        _kPrefsKey, DateTime.now().millisecondsSinceEpoch);

    await _fetchBatch();
  }

  // ── Fetch next batch from Firestore ───────────────────────────────────

  Future<void> _fetchBatch() async {
    if (!mounted) return;
    final firestore = FirebaseFirestore.instance;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final newItems = <_ActivityItem>[];

    try {
      // ── Posts (cursor-paginated via orderBy) ──────────────────────────
      if (!_postsDone) {
        var query = firestore
            .collection(AppConstants.postsCollection)
            .orderBy('createdAt', descending: true)
            .limit(_fetchSize);
        if (_lastPostDoc != null) {
          query = query.startAfterDocument(_lastPostDoc!);
        }

        final snap = await query.get();
        if (snap.docs.length < _fetchSize) _postsDone = true;
        if (snap.docs.isNotEmpty) _lastPostDoc = snap.docs.last;

        for (final doc in snap.docs) {
          final data = doc.data();
          final ts = data['createdAt'] as Timestamp?;
          if (ts == null) continue;
          final date = ts.toDate();
          if (date.isBefore(thirtyDaysAgo)) {
            _postsDone = true;
            break;
          }
          final title = data['title'] as String? ?? '';
          newItems.add(_ActivityItem(
            type: 'post',
            title: title.isNotEmpty ? title : 'עדכון חדש',
            subtitle: data['authorName'] as String? ?? '',
            date: date,
            icon: Icons.newspaper_rounded,
            color: const Color(0xFFF59E0B),
            isNew: date.isAfter(_lastVisited),
          ));
        }
      }

      // ── Shifts + Tasks (fetched once, client-side sorted) ─────────────
      if (!_othersDone) {
        // Shifts
        Query<Map<String, dynamic>> shiftsQ =
            firestore.collection(AppConstants.shiftsCollection);
        if (_role == 'worker') {
          shiftsQ = shiftsQ.where('assignedWorkers', arrayContains: _uid);
        }
        final shiftsSnap = await shiftsQ.limit(60).get();

        for (final doc in shiftsSnap.docs) {
          final data = doc.data();
          final effective =
              (data['lastUpdatedAt'] ?? data['createdAt']) as Timestamp?;
          if (effective == null) continue;
          final date = effective.toDate();
          if (date.isBefore(thirtyDaysAgo)) continue;
          final shiftDate = data['date'] as String? ?? '';
          final shiftTitle = data['title'] as String? ?? '';
          newItems.add(_ActivityItem(
            type: 'shift',
            title: shiftTitle.isNotEmpty
                ? shiftTitle
                : shiftDate.isNotEmpty
                    ? 'משמרת $shiftDate'
                    : 'עדכון משמרת',
            subtitle: _role == 'worker' ? 'שובצת למשמרת' : 'עדכון משמרת',
            date: date,
            icon: Icons.schedule_rounded,
            color: const Color(0xFF4F46E5),
            isNew: date.isAfter(_lastVisited),
          ));
        }

        // Tasks
        Query<Map<String, dynamic>> tasksQ =
            firestore.collection(AppConstants.tasksCollection);
        tasksQ = _role == 'worker'
            ? tasksQ.where('assignedTo', arrayContains: _uid)
            : tasksQ.where('createdBy', isEqualTo: _uid);
        final tasksSnap = await tasksQ.limit(60).get();

        for (final doc in tasksSnap.docs) {
          final data = doc.data();
          final ts = data['createdAt'] as Timestamp?;
          if (ts == null) continue;
          final date = ts.toDate();
          if (date.isBefore(thirtyDaysAgo)) continue;
          newItems.add(_ActivityItem(
            type: 'task',
            title: data['title'] as String? ?? 'משימה',
            subtitle: _role == 'worker' ? 'הוקצתה אליך' : 'יצרת משימה חדשה',
            date: date,
            icon: Icons.task_alt_rounded,
            color: const Color(0xFF8B5CF6),
            isNew: date.isAfter(_lastVisited),
          ));
        }

        _othersDone = true;
      }

      // Merge into master list and re-sort
      _allItems.addAll(newItems);
      _allItems.sort((a, b) => b.date.compareTo(a.date));

      // Advance display window
      _displayCount =
          (_displayCount + _pageSize).clamp(0, _allItems.length);
    } catch (e) {
      debugPrint('NotificationHistoryScreen fetch error: $e');
      if (mounted) setState(() => _error = 'שגיאה בטעינת הנתונים');
    }

    if (mounted) {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // ── Load more (scroll-triggered) ──────────────────────────────────────

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isInitialLoading) return;
    if (!_hasMore) return;

    if (_displayCount < _allItems.length) {
      // Show next page from already-fetched buffer — no Firestore read
      setState(() {
        _displayCount =
            (_displayCount + _pageSize).clamp(0, _allItems.length);
      });
      return;
    }

    if (!_postsDone) {
      // Need to fetch more posts from Firestore
      setState(() => _isLoadingMore = true);
      await _fetchBatch();
    }
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────

  Future<void> _refresh() async {
    _allItems.clear();
    _displayCount = 0;
    _lastPostDoc = null;
    _postsDone = false;
    _othersDone = false;
    _error = null;
    setState(() => _isInitialLoading = true);
    await _fetchBatch();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays == 1) return 'אתמול';
    return 'לפני ${diff.inDays} ימים';
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final visible = _allItems.take(_displayCount).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TaskTheme.background,
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),

            // ── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('פעילות אחרונה', style: TaskTheme.heading2),
                  ),
                  if (!_isInitialLoading && visible.isNotEmpty)
                    Text('${visible.length} מתוך ${_allItems.length}',
                        style: TaskTheme.caption),
                ],
              ),
            ),

            // ── Content ────────────────────────────────────────────────
            if (_isInitialLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: _buildError())
            else if (visible.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: visible.length + (_hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == visible.length) return _buildLoadingFooter();
                      return _buildItem(visible[i]);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Empty / error / footer ────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text('אין פעילות אחרונה',
              style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary)),
          const SizedBox(height: 6),
          const Text('עדכונים חדשים יופיעו כאן', style: TaskTheme.caption),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: TaskTheme.overdue),
          const SizedBox(height: 12),
          Text(_error!, style: TaskTheme.body),
          const SizedBox(height: 12),
          TextButton(onPressed: _refresh, child: const Text('נסה שוב')),
        ],
      ),
    );
  }

  Widget _buildLoadingFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  // ── Item tile ─────────────────────────────────────────────────────────

  Widget _buildItem(_ActivityItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: item.isNew
            ? item.color.withOpacity(0.06)
            : TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        boxShadow: TaskTheme.softShadow,
        border: Border(
          right: BorderSide(
            color: item.color,
            width: item.isNew ? 4 : 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withOpacity(item.isNew ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.title, style: TaskTheme.heading3),
                      ),
                      if (item.isNew) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: item.color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'חדש',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (item.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(item.subtitle,
                        style: TaskTheme.body
                            .copyWith(color: TaskTheme.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 4),
                  Text(_relativeTime(item.date), style: TaskTheme.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────

class _ActivityItem {
  final String type;
  final String title;
  final String subtitle;
  final DateTime date;
  final IconData icon;
  final Color color;
  final bool isNew;

  const _ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.color,
    this.isNew = false,
  });
}
