import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Remove token from Firestore (call on logout)
  Future<void> removeTokenOnLogout() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await getToken();
    if (token == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
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
}
