import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/core/constants/app_constants.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

/// Service for handling push notifications via Firebase Cloud Messaging
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;

  /// Android notification channel for high importance notifications
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'park_janana_notifications',
    'Park Janana Notifications',
    description: 'Notifications for shifts, tasks, and messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Request permission
    await _requestPermission();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up message handlers
    _setupMessageHandlers();

    // Get and save FCM token
    await _saveTokenToFirestore();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateTokenInFirestore);

    _isInitialized = true;
    debugPrint('NotificationService initialized');
  }

  /// Request notification permissions
  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    final isAuthorized =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('Notification permission: ${settings.authorizationStatus}');
    return isAuthorized;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channel
    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
  }

  /// Set up FCM message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  /// Handle messages when app is in foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    await _showLocalNotification(
      title: notification.title ?? 'Park Janana',
      body: notification.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Handle when user taps notification to open app
  void _handleNotificationOpen(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    // TODO: Navigate based on message.data
  }

  /// Check if app was opened from a notification when terminated
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state: ${initialMessage.data}');
      // TODO: Navigate based on initialMessage.data
    }
  }

  /// Show a local notification
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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Get the current FCM token
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Save FCM token to Firestore for the current user
  Future<void> _saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await getToken();
    if (token == null) return;

    await _updateTokenInFirestore(token);
  }

  /// Update token in Firestore
  Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Save FCM token after user login (public method)
  Future<void> saveTokenAfterLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('saveTokenAfterLogin: No user logged in');
      return;
    }

    final token = await getToken();
    if (token == null) {
      debugPrint('saveTokenAfterLogin: No FCM token available');
      return;
    }

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved after login for user: ${user.uid}');
    } catch (e) {
      debugPrint('Error saving FCM token after login: $e');
    }
  }

  /// Remove token from Firestore (call on logout)
  Future<void> removeTokenOnLogout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await getToken();
    if (token == null) return;

    try {
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([token]),
      });
      debugPrint('FCM token removed from Firestore');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  /// Subscribe to a topic (e.g., department-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  // ═══════════════════════════════════════════════════════════
  // SHIFT NOTIFICATIONS
  // ═══════════════════════════════════════════════════════════

  /// Send notification about shift updates to affected workers
  /// Creates a notification request in Firestore to be processed by Cloud Functions
  Future<void> notifyShiftUpdate({
    required String shiftId,
    required List<String> workerIds,
    required String shiftDate,
    required String department,
    required List<String> changes,
  }) async {
    if (workerIds.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Create notification request for Cloud Function to process
      await _firestore.collection(AppConstants.notificationRequestsCollection).add({
        'type': 'shift_update',
        'shiftId': shiftId,
        'recipientIds': workerIds,
        'title': 'עדכון משמרת - $department',
        'body': 'המשמרת ב-$shiftDate עודכנה: ${changes.join(', ')}',
        'data': {
          'type': 'shift_update',
          'shiftId': shiftId,
          'changes': changes,
        },
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Shift update notification request created for ${workerIds.length} workers');
    } catch (e) {
      debugPrint('Error creating shift update notification: $e');
    }
  }

  /// Send notification when a worker is assigned to a shift
  Future<void> notifyWorkerAssigned({
    required String workerId,
    required String shiftId,
    required String shiftDate,
    required String department,
    required String startTime,
    required String endTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(AppConstants.notificationRequestsCollection).add({
        'type': 'shift_assigned',
        'shiftId': shiftId,
        'recipientIds': [workerId],
        'title': 'שובצת למשמרת!',
        'body': '$department - $shiftDate, $startTime-$endTime',
        'data': {
          'type': 'shift_assigned',
          'shiftId': shiftId,
        },
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Worker assigned notification request created');
    } catch (e) {
      debugPrint('Error creating worker assigned notification: $e');
    }
  }

  /// Send notification when a worker is removed from a shift
  Future<void> notifyWorkerRemoved({
    required String workerId,
    required String shiftId,
    required String shiftDate,
    required String department,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(AppConstants.notificationRequestsCollection).add({
        'type': 'shift_removed',
        'shiftId': shiftId,
        'recipientIds': [workerId],
        'title': 'הוסרת ממשמרת',
        'body': '$department - $shiftDate',
        'data': {
          'type': 'shift_removed',
          'shiftId': shiftId,
        },
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Worker removed notification request created');
    } catch (e) {
      debugPrint('Error creating worker removed notification: $e');
    }
  }

  /// Send notification when a shift is cancelled
  Future<void> notifyShiftCancelled({
    required String shiftId,
    required List<String> workerIds,
    required String shiftDate,
    required String department,
    String? reason,
  }) async {
    if (workerIds.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(AppConstants.notificationRequestsCollection).add({
        'type': 'shift_cancelled',
        'shiftId': shiftId,
        'recipientIds': workerIds,
        'title': 'משמרת בוטלה',
        'body': '$department - $shiftDate${reason != null ? '\nסיבה: $reason' : ''}',
        'data': {
          'type': 'shift_cancelled',
          'shiftId': shiftId,
          'reason': reason,
        },
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Shift cancelled notification request created for ${workerIds.length} workers');
    } catch (e) {
      debugPrint('Error creating shift cancelled notification: $e');
    }
  }

  /// Send notification for new message in shift
  Future<void> notifyNewShiftMessage({
    required String shiftId,
    required List<String> workerIds,
    required String department,
    required String senderName,
  }) async {
    if (workerIds.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection(AppConstants.notificationRequestsCollection).add({
        'type': 'shift_message',
        'shiftId': shiftId,
        'recipientIds': workerIds,
        'title': 'הודעה חדשה - $department',
        'body': 'הודעה חדשה מ-$senderName',
        'data': {
          'type': 'shift_message',
          'shiftId': shiftId,
        },
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('Shift message notification request created');
    } catch (e) {
      debugPrint('Error creating shift message notification: $e');
    }
  }
}
