import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:park_janana/core/constants/app_constants.dart';

class HomeBadgeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, int> _badgeCounts = {};
  final Map<String, Timestamp> _lastVisited = {};
  final List<StreamSubscription> _subscriptions = [];

  String? _userId;
  String? _userRole;
  bool _initialized = false;
  bool _initializing = false;

  int getBadgeCount(String section) => _badgeCounts[section] ?? 0;

  /// Get last visited timestamp for a section (used by shift screens for day-level dots).
  Timestamp? getLastVisited(String section) => _lastVisited[section];

  /// Initialize the provider for a specific user.
  Future<void> init({
    required String userId,
    required String userRole,
  }) async {
    if ((_initialized && _userId == userId) || _initializing) return;
    _initializing = true;

    try {
      _cancelSubscriptions();
      _badgeCounts.clear();
      _lastVisited.clear();

      _userId = userId;
      _userRole = userRole;

      await _loadLastVisitedTimestamps();
      _startListening();

      _initialized = true;
    } catch (e) {
      debugPrint('HomeBadgeProvider init error: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<void> _loadLastVisitedTimestamps() async {
    final prefs = await SharedPreferences.getInstance();
    final sections = ['schedule', 'newsfeed', 'shifts', 'tasks'];
    final now = Timestamp.now();

    for (final section in sections) {
      // Use microsecond key for higher precision; fall back to old millis key.
      final microKey = 'badge_lastVisited_micro_${section}_$_userId';
      final oldKey = 'badge_lastVisited_${section}_$_userId';
      final micros = prefs.getInt(microKey);
      if (micros != null) {
        _lastVisited[section] = Timestamp.fromMicrosecondsSinceEpoch(micros);
      } else {
        final millis = prefs.getInt(oldKey);
        if (millis != null) {
          _lastVisited[section] = Timestamp.fromMillisecondsSinceEpoch(millis);
        } else {
          _lastVisited[section] = now;
        }
        // Migrate to micro key
        await prefs.setInt(
            microKey, (_lastVisited[section]!).microsecondsSinceEpoch);
      }
      // Initialize badge count to 0 to avoid null-vs-0 false changes
      _badgeCounts[section] = 0;
    }
  }

  void _startListening() {
    _listenToNewsfeed();
    _listenToShifts();
    _listenToTasks();
  }

  void _listenToNewsfeed() {
    final sub = _firestore
        .collection(AppConstants.postsCollection)
        .snapshots()
        .listen((snapshot) {
      final lastVisited = _lastVisited['newsfeed'];
      if (lastVisited == null) return;
      int count = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = data['createdAt'] as Timestamp?;
        final updatedAt = data['updatedAt'] as Timestamp?;
        final effective = updatedAt ?? createdAt;
        if (effective != null && effective.compareTo(lastVisited) > 0) {
          count++;
        }
      }
      if (_badgeCounts['newsfeed'] != count) {
        _badgeCounts['newsfeed'] = count;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('HomeBadgeProvider newsfeed error: $e');
    });
    _subscriptions.add(sub);
  }

  void _listenToShifts() {
    if (_userRole == 'worker') {
      _listenToShiftsForWorker();
    } else {
      _listenToShiftsForManager();
    }
  }

  /// Worker: schedule badge only counts shifts the worker was actively
  /// assigned to (decision == 'accepted' and decisionAt after last visit).
  /// Shifts badge also uses decisionAt — not lastUpdatedAt — so generic
  /// edits to a shift (like adding another worker) don't trigger badges.
  void _listenToShiftsForWorker() {
    final stream = _firestore
        .collection(AppConstants.shiftsCollection)
        .where('assignedWorkers', arrayContains: _userId)
        .snapshots();

    final sub = stream.listen((snapshot) {
      try {
        final lastVisitedSchedule = _lastVisited['schedule'];
        final lastVisitedShifts = _lastVisited['shifts'];
        if (lastVisitedSchedule == null || lastVisitedShifts == null) return;

        int scheduleCount = 0;
        int shiftsCount = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final assignedWorkerData =
              List<Map<String, dynamic>>.from(data['assignedWorkerData'] ?? []);

          // Find this worker's entry in assignedWorkerData
          Timestamp? workerDecisionAt;
          for (final entry in assignedWorkerData) {
            if (entry['userId'] == _userId && entry['decision'] == 'accepted') {
              final raw = entry['decisionAt'];
              if (raw is Timestamp) {
                workerDecisionAt = raw;
              }
              break;
            }
          }

          // If no valid decisionAt found, skip this shift entirely
          if (workerDecisionAt == null) continue;

          // Schedule badge: worker was assigned after last schedule visit
          if (workerDecisionAt.compareTo(lastVisitedSchedule) > 0) {
            scheduleCount++;
          }

          // Shifts badge: worker was assigned after last shifts visit
          if (workerDecisionAt.compareTo(lastVisitedShifts) > 0) {
            shiftsCount++;
          }
        }

        final changed = _badgeCounts['schedule'] != scheduleCount ||
            _badgeCounts['shifts'] != shiftsCount;
        _badgeCounts['schedule'] = scheduleCount;
        _badgeCounts['shifts'] = shiftsCount;
        if (changed) notifyListeners();
      } catch (e) {
        debugPrint('HomeBadgeProvider worker shifts error: $e');
      }
    }, onError: (e) {
      debugPrint('HomeBadgeProvider shifts stream error: $e');
    });
    _subscriptions.add(sub);
  }

  /// Manager: any new/updated shift counts for both schedule and shifts badges.
  void _listenToShiftsForManager() {
    final stream =
        _firestore.collection(AppConstants.shiftsCollection).snapshots();

    final sub = stream.listen((snapshot) {
      try {
        final lastVisitedSchedule = _lastVisited['schedule'];
        final lastVisitedShifts = _lastVisited['shifts'];
        if (lastVisitedSchedule == null || lastVisitedShifts == null) return;

        int scheduleCount = 0;
        int shiftsCount = 0;

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final lastUpdatedAt = data['lastUpdatedAt'] as Timestamp?;
          final createdAt = data['createdAt'] as Timestamp?;
          final effective = lastUpdatedAt ?? createdAt;
          if (effective == null) continue;

          if (effective.compareTo(lastVisitedSchedule) > 0) {
            scheduleCount++;
          }
          if (effective.compareTo(lastVisitedShifts) > 0) {
            shiftsCount++;
          }
        }

        final changed = _badgeCounts['schedule'] != scheduleCount ||
            _badgeCounts['shifts'] != shiftsCount;
        _badgeCounts['schedule'] = scheduleCount;
        _badgeCounts['shifts'] = shiftsCount;
        if (changed) notifyListeners();
      } catch (e) {
        debugPrint('HomeBadgeProvider manager shifts error: $e');
      }
    }, onError: (e) {
      debugPrint('HomeBadgeProvider shifts stream error: $e');
    });
    _subscriptions.add(sub);
  }

  void _listenToTasks() {
    Stream<QuerySnapshot<Map<String, dynamic>>> stream;

    if (_userRole == 'worker') {
      stream = _firestore
          .collection(AppConstants.tasksCollection)
          .where('assignedTo', arrayContains: _userId)
          .snapshots();
    } else {
      stream = _firestore
          .collection(AppConstants.tasksCollection)
          .where('createdBy', isEqualTo: _userId)
          .snapshots();
    }

    final sub = stream.listen((snapshot) {
      final lastVisited = _lastVisited['tasks'];
      if (lastVisited == null) return;
      int count = 0;
      for (final doc in snapshot.docs) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        if (createdAt != null && createdAt.compareTo(lastVisited) > 0) {
          count++;
        }
      }
      if (_badgeCounts['tasks'] != count) {
        _badgeCounts['tasks'] = count;
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('HomeBadgeProvider tasks error: $e');
    });
    _subscriptions.add(sub);
  }

  /// Mark a section as visited. Resets its badge count to 0.
  Future<void> markSectionVisited(String section) async {
    final now = Timestamp.now();
    _lastVisited[section] = now;
    _badgeCounts[section] = 0;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final microKey = 'badge_lastVisited_micro_${section}_$_userId';
      await prefs.setInt(microKey, now.microsecondsSinceEpoch);
    } catch (e) {
      debugPrint('HomeBadgeProvider markVisited error: $e');
    }
  }

  void _cancelSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
