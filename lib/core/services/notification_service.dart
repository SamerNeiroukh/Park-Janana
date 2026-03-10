import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/screens/manager_weekly_schedule_screen.dart';
import 'package:park_janana/features/shifts/screens/shift_details_screen.dart';
import 'package:park_janana/features/shifts/screens/shifts_screen.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/features/tasks/models/task_model.dart';
import 'package:park_janana/features/tasks/screens/manager_task_board_screen.dart';
import 'package:park_janana/features/tasks/screens/task_details_screen.dart';
import 'package:park_janana/features/tasks/screens/worker_task_timeline_screen.dart';
import 'package:park_janana/features/newsfeed/screens/newsfeed_screen.dart';
import 'package:park_janana/features/workers/screens/manage_workers_screen.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/main.dart' show navigatorKey;

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

/// Singleton service for FCM push notifications + deep link routing.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Holds FCM data from a terminated-state launch until HomeScreen is ready.
  /// Static so it survives the singleton lifetime.
  static Map<String, dynamic>? _pendingNavigationData;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'park_janana_notifications',
    'Park Janana Notifications',
    description: 'Notifications for shifts, tasks, and messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ── Initialisation ──────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    tz_data.initializeTimeZones();
    // tz.local is a `late` field — must be set explicitly after initializeTimeZones().
    tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
    await _requestPermission();
    await _initializeLocalNotifications();
    _setupMessageHandlers();
    await _saveTokenToFirestore();
    _messaging.onTokenRefresh.listen(_updateTokenInFirestore);
    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;
    debugPrint('Notification permission: ${settings.authorizationStatus}');
    return isAuthorized;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  // ── Message handlers ────────────────────────────────────────────────────

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);
    _checkInitialMessage();
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message: ${message.notification?.title}');
    final notification = message.notification;
    if (notification == null) return;
    await _showLocalNotification(
      title: notification.title ?? 'Park Janana',
      body: notification.body ?? '',
      payload: json.encode(message.data),
    );
  }

  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    _navigateFromNotification(message.data);
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state — navigation deferred until HomeScreen mounts');
      // Do NOT navigate here — the navigator doesn't exist yet (called before runApp)
      // and the 6-second splash screen is still showing. Store for HomeScreen to consume.
      _pendingNavigationData = Map<String, dynamic>.from(initialMessage.data);
    }
  }

  /// Called by HomeScreen after it fully mounts and auth is confirmed.
  /// Consumes any terminated-state notification and navigates to the correct screen.
  void consumePendingNavigation() {
    final data = _pendingNavigationData;
    if (data == null) return;
    _pendingNavigationData = null;
    debugPrint('Consuming pending terminated-state notification');
    // Brief delay so HomeScreen finishes its first render before we push on top.
    Future.delayed(const Duration(milliseconds: 300), () {
      _navigateFromNotification(data);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null && response.payload!.isNotEmpty) {
      try {
        final data = Map<String, dynamic>.from(json.decode(response.payload!));
        _navigateFromNotification(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
        _navigateToHome();
      }
    }
  }

  // ── Deep link navigation ────────────────────────────────────────────────

  /// Route to the correct screen based on notification type.
  /// Payload may use `entityId` (new format) or legacy `shiftId`/`taskId` keys.
  void _navigateFromNotification(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type'] as String?;

    // ── Security: reject if this notification was not meant for the current user.
    // Prevents a logged-out user's stale notification from being tapped by a
    // different user who logs in on the same device.
    // Clock-out reminders are device-local and carry no recipientId — they fall
    // through to the default case (no navigation) so the check is skipped for them.
    final recipientId = data['recipientId'] as String?;
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (type != 'clock_reminder') {
      if (recipientId == null || recipientId.isEmpty) {
        debugPrint(
          'SECURITY: recipientId absent for type=$type — navigation blocked',
        );
        return;
      }
      if (currentUid == null || currentUid != recipientId) {
        debugPrint(
          'Notification rejected — intended for $recipientId, '
          'current user is $currentUid',
        );
        return;
      }
    }
    final entityId = ((data['entityId'] as String?)?.isNotEmpty ?? false)
        ? data['entityId'] as String
        : (data['shiftId'] as String?) ??
          (data['taskId'] as String?) ??
          (data['userId'] as String?);

    debugPrint('Deep link: type=$type, entityId=$entityId');

    // Always ensure /home is the base of the stack
    navigator.pushNamedAndRemoveUntil('/home', (route) => false);

    switch (type) {
      case 'shift_assigned':
      case 'shift_update':
      case 'shift_removed':
      case 'shift_cancelled':
      case 'shift_rejected':
        if (entityId != null) _pushShiftDetails(navigator, entityId);
      case 'shift_message':
        if (entityId != null) _pushShiftDetails(navigator, entityId, initialTab: 2);
      case 'task_assigned':
      case 'task_approved':
        if (entityId != null) _pushTaskDetails(navigator, entityId);
      case 'task_review_requested':
        if (entityId != null) _pushManagerBoardHighlight(navigator, entityId);
      case 'task_comment':
        if (entityId != null) _pushTaskDetails(navigator, entityId, initialTab: 1, withBase: false);
      case 'post_comment':
        if (entityId != null) _pushPostDetail(navigator, entityId);
      case 'new_user_pending':
        _pushManageWorkers(navigator);
      default:
        // worker_approved / worker_rejected / unknown — stay on home
        break;
    }
  }

  /// Returns the current user's role from Firestore.
  /// Defaults to 'worker' on any error or missing field — the safest role.
  Future<String> _fetchCurrentRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'worker';
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      return doc.data()?['role'] as String? ?? 'worker';
    } catch (_) {
      return 'worker';
    }
  }

  Future<void> _pushShiftDetails(NavigatorState nav, String shiftId, {int initialTab = 0}) async {
    try {
      final role = await _fetchCurrentRole();
      final doc = await _firestore
          .collection(AppConstants.shiftsCollection)
          .doc(shiftId)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final shift = ShiftModel.fromMap(doc.id, doc.data()!);

      if (role == 'worker') {
        // Worker: open My Shifts screen jumping to the shift's date,
        // with the ShiftDetailsPopup auto-opened.
        nav.push(MaterialPageRoute(
          builder: (_) => ShiftsScreen(initialShift: shift),
        ));
      } else {
        // Manager/owner/admin: weekly overview with shift details stacked on
        // top. Back-press from ShiftDetailsScreen returns to the overview.
        nav.push(MaterialPageRoute(
          builder: (_) => const ManagerWeeklyScheduleScreen(),
        ));
        nav.push(MaterialPageRoute(
          builder: (_) => ShiftDetailsScreen(
            shift: shift,
            shiftService: ShiftService(),
            workerService: WorkerService(),
            initialTab: initialTab,
          ),
        ));
      }
    } catch (e) {
      debugPrint('_pushShiftDetails error: $e');
    }
  }

  Future<void> _pushTaskDetails(NavigatorState nav, String taskId,
      {int initialTab = 0, bool withBase = true}) async {
    try {
      final role = await _fetchCurrentRole();
      final doc = await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final task = TaskModel.fromMap(doc.id, doc.data()!);

      if (withBase) {
        if (role == 'worker') {
          nav.push(MaterialPageRoute(
            builder: (_) => const WorkerTaskTimelineScreen(),
          ));
        } else {
          nav.push(MaterialPageRoute(
            builder: (_) => const ManagerTaskBoardScreen(initialTab: 1),
          ));
        }
      }
      nav.push(MaterialPageRoute(
        builder: (_) => TaskDetailsScreen(task: task, initialTab: initialTab),
      ));
    } catch (e) {
      debugPrint('_pushTaskDetails error: $e');
    }
  }

  void _pushPostDetail(NavigatorState nav, String postId) {
    nav.push(MaterialPageRoute(
      builder: (_) => NewsfeedScreen(initialPostId: postId),
    ));
  }

  Future<void> _pushManagerBoardHighlight(NavigatorState nav, String taskId) async {
    final role = await _fetchCurrentRole();
    if (role != 'manager' && role != 'owner' && role != 'co_owner' && role != 'admin') {
      debugPrint('ManagerBoardHighlight blocked — role=$role is not authorized');
      return;
    }
    nav.push(MaterialPageRoute(
      builder: (_) => ManagerTaskBoardScreen(
        initialTab: 0,
        highlightTaskId: taskId,
      ),
    ));
  }

  Future<void> _pushManageWorkers(NavigatorState nav) async {
    final role = await _fetchCurrentRole();
    if (role != 'manager' && role != 'owner' && role != 'co_owner' && role != 'admin') {
      debugPrint('ManageWorkers blocked — role=$role is not authorized');
      return;
    }
    nav.push(MaterialPageRoute(builder: (_) => const ManageWorkersScreen()));
  }

  void _navigateToHome() {
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // ── Local notification display ──────────────────────────────────────────

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'park_janana_notifications',
      'Park Janana Notifications',
      channelDescription: 'Notifications for shifts, tasks, and messages',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ── FCM token management ────────────────────────────────────────────────

  Future<String?> getToken() async => _messaging.getToken();

  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await getToken();
    if (token == null) return;
    await _updateTokenInFirestore(token);
  }

  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _saveTokenCapped(user.uid, token);
      debugPrint('FCM token saved');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> saveTokenAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await getToken();
    if (token == null) return;
    try {
      await _saveTokenCapped(user.uid, token);
      debugPrint('FCM token saved after login');
    } catch (e) {
      debugPrint('Error saving FCM token after login: $e');
    }
  }

  /// Saves [token] to Firestore, deduplicating and keeping at most 5 tokens.
  /// Skips the transaction entirely if this token was already saved on this
  /// device — FCM tokens rotate infrequently, so this eliminates a Firestore
  /// read+write on every app launch for users whose token hasn't changed.
  Future<void> _saveTokenCapped(String uid, String token) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString('fcm_last_token_$uid');
    if (cachedToken == token) {
      debugPrint('FCM token unchanged — skipping Firestore update');
      return;
    }

    final docRef =
        _firestore.collection(AppConstants.usersCollection).doc(uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      List<dynamic> tokens =
          List<dynamic>.from(snapshot.data()?['fcmTokens'] ?? []);
      tokens.remove(token); // dedup — remove stale copy of same token
      tokens.add(token); // append as most-recent
      if (tokens.length > 5) tokens = tokens.sublist(tokens.length - 5);
      transaction.update(docRef, {
        'fcmTokens': tokens,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    });

    // Cache the token so future app launches skip this transaction.
    await prefs.setString('fcm_last_token_$uid', token);
  }

  Future<void> removeTokenOnLogout() async {
    // Clear all OS-level notifications so the next user on this device
    // cannot tap notifications that were intended for the previous user.
    await _localNotifications.cancelAll();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final token = await getToken();
    if (token == null) return;
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
      // Clear locally-cached token so the next login forces a fresh Firestore save.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('fcm_last_token_${user.uid}');
      debugPrint('FCM token removed on logout');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // ── Clock-out reminders ─────────────────────────────────────────────────

  /// Unique notification IDs reserved for clock-out reminders.
  static const int _clockReminder10hId = 9001;
  static const int _clockReminder12hId = 9002;

  static const AndroidNotificationDetails _reminderAndroid =
      AndroidNotificationDetails(
    'clock_reminders',
    'תזכורות יציאה',
    channelDescription: 'תזכורות לדווח יציאה ממשמרת',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  static const DarwinNotificationDetails _reminderIOS =
      DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  static const NotificationDetails _reminderDetails =
      NotificationDetails(android: _reminderAndroid, iOS: _reminderIOS);

  /// Schedule local reminders at clockIn + 10 h and clockIn + 12 h.
  /// Safe to call multiple times — cancels any existing reminders first.
  Future<void> scheduleClockOutReminders(DateTime clockInTime) async {
    await cancelClockOutReminders();

    final local = tz.local;
    final now = tz.TZDateTime.now(local);

    final remind10h = tz.TZDateTime.from(
      clockInTime.add(const Duration(hours: 10)),
      local,
    );
    final remind12h = tz.TZDateTime.from(
      clockInTime.add(const Duration(hours: 12)),
      local,
    );

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (remind10h.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        _clockReminder10hId,
        'שכחת לצאת? ⏰',
        'אתה במשמרת כבר 10 שעות. זכור לדווח יציאה.',
        remind10h,
        _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '{"type":"clock_reminder","recipientId":"$uid"}',
      );
      debugPrint('Clock-out reminder scheduled for 10h: $remind10h');
    }

    if (remind12h.isAfter(now)) {
      await _localNotifications.zonedSchedule(
        _clockReminder12hId,
        'משמרת ארוכה מאוד! 🚨',
        'אתה במשמרת כבר 12 שעות. דווח יציאה בהקדם.',
        remind12h,
        _reminderDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '{"type":"clock_reminder","recipientId":"$uid"}',
      );
      debugPrint('Clock-out reminder scheduled for 12h: $remind12h');
    }
  }

  /// Cancel both clock-out reminders (call on clock-out).
  Future<void> cancelClockOutReminders() async {
    await _localNotifications.cancel(_clockReminder10hId);
    await _localNotifications.cancel(_clockReminder12hId);
    debugPrint('Clock-out reminders cancelled');
  }

  // ── Task deadline reminders ─────────────────────────────────────────────

  static const AndroidNotificationDetails _taskReminderAndroid =
      AndroidNotificationDetails(
    'task_deadlines',
    'תזכורות משימות',
    channelDescription: 'תזכורות 24 שעות לפני מועד הגשת משימה',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _taskReminderDetails = NotificationDetails(
    android: _taskReminderAndroid,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  /// Converts a task ID string to a stable positive int notification ID.
  int _taskNotifId(String taskId) =>
      taskId.hashCode.abs() % 90000 + 10000; // range 10000–99999

  /// Schedule a local reminder 24 h before [dueDate] for a task.
  /// Safe to call repeatedly — silently skips if the reminder time is past.
  Future<void> scheduleTaskDeadlineReminder({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    final local = tz.local;
    final reminderTime = tz.TZDateTime.from(
      dueDate.subtract(const Duration(hours: 24)),
      local,
    );
    final now = tz.TZDateTime.now(local);
    if (!reminderTime.isAfter(now)) return; // already past — skip

    final id = _taskNotifId(taskId);
    await _localNotifications.zonedSchedule(
      id,
      'תזכורת משימה ⏰',
      '$taskTitle — נותרו פחות מ-24 שעות לסיום',
      reminderTime,
      _taskReminderDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '{"type":"task_assigned","entityId":"$taskId","recipientId":"${FirebaseAuth.instance.currentUser?.uid ?? ""}"}',
    );
    debugPrint('Task deadline reminder scheduled: $taskTitle @ $reminderTime');
  }

  /// Cancel the deadline reminder for a specific task.
  Future<void> cancelTaskDeadlineReminder(String taskId) async {
    await _localNotifications.cancel(_taskNotifId(taskId));
    debugPrint('Task deadline reminder cancelled for $taskId');
  }
}
