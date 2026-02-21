import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/tasks/theme/task_theme.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState
    extends State<NotificationHistoryScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notification_history') ?? [];
    final parsed = raw
        .map((s) {
          try {
            return Map<String, dynamic>.from(json.decode(s));
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
    if (mounted) setState(() { _notifications = parsed; _isLoading = false; });
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notification_history');
    if (mounted) setState(() => _notifications = []);
  }

  Future<void> _removeAt(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('notification_history') ?? [];
    if (index < raw.length) raw.removeAt(index);
    await prefs.setStringList('notification_history', raw);
    if (mounted) {
      setState(() => _notifications.removeAt(index));
    }
  }

  String _relativeTime(int timestampMs) {
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(timestampMs));
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דקות';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays == 1) return 'אתמול';
    return 'לפני ${diff.inDays} ימים';
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'shift_assigned':
        return Icons.event_available_rounded;
      case 'shift_removed':
        return Icons.event_busy_rounded;
      case 'shift_update':
        return Icons.update_rounded;
      case 'shift_cancelled':
        return Icons.cancel_rounded;
      case 'shift_message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForType(String? type) {
    switch (type) {
      case 'shift_assigned':
        return TaskTheme.done;
      case 'shift_removed':
      case 'shift_cancelled':
        return TaskTheme.overdue;
      case 'shift_update':
        return TaskTheme.inProgress;
      case 'shift_message':
        return TaskTheme.primary;
      default:
        return TaskTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    child: Text('התראות', style: TaskTheme.heading2),
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.delete_sweep_rounded,
                          size: 18, color: TaskTheme.overdue),
                      label: const Text('מחק הכל',
                          style: TextStyle(
                              color: TaskTheme.overdue,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_notifications.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildItem(index);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_none_rounded,
              size: 64, color: TaskTheme.textTertiary),
          const SizedBox(height: 12),
          Text(
            'אין התראות',
            style: TaskTheme.body.copyWith(color: TaskTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index) {
    final n = _notifications[index];
    final title = n['title'] as String? ?? '';
    final body = n['body'] as String? ?? '';
    final type = n['type'] as String?;
    final ts = n['timestamp'] as int? ?? 0;
    final color = _colorForType(type);
    final icon = _iconForType(type);

    return Dismissible(
      key: ValueKey('$index-$ts'),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => _removeAt(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TaskTheme.overdue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: TaskTheme.overdue, size: 24),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TaskTheme.surface,
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          boxShadow: TaskTheme.softShadow,
          border: Border(
            right: BorderSide(color: color, width: 3),
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TaskTheme.heading3),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(body,
                          style: TaskTheme.body
                              .copyWith(color: TaskTheme.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 4),
                    Text(ts > 0 ? _relativeTime(ts) : '',
                        style: TaskTheme.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
