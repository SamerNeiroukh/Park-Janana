import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/custom_exception.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Notification categories
  static const String categoryShifts = 'shifts';
  static const String categoryTasks = 'tasks';
  static const String categoryAnnouncements = 'announcements';

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permissions
      await requestPermissions();

      // Get and store FCM token
      await _updateFCMToken();

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      debugPrint('✅ NotificationService initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing NotificationService: $e');
      throw CustomException('שגיאה באתחול שירות ההתראות');
    }
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      bool isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                      settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('Notification permissions granted: $isGranted');
      return isGranted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  /// Get FCM token and update user document
  Future<String?> _updateFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('✅ FCM token updated for user: $userId');
        }
      }
      return token;
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return null;
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.data}');
    
    // Show in-app notification or handle accordingly
    if (message.notification != null) {
      _showInAppNotification(
        message.notification!.title ?? '',
        message.notification!.body ?? '',
        message.data,
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');
    
    // Navigate based on notification data
    final data = message.data;
    if (data.containsKey('type')) {
      _navigateBasedOnType(data);
    }
  }

  /// Show in-app notification
  void _showInAppNotification(String title, String body, Map<String, dynamic> data) {
    // This would typically show a snackbar or dialog
    // Implementation depends on your app's navigation structure
    debugPrint('In-app notification: $title - $body');
  }

  /// Navigate based on notification type
  void _navigateBasedOnType(Map<String, dynamic> data) {
    final type = data['type'];
    switch (type) {
      case 'shift_approved':
      case 'shift_removed':
        // Navigate to shifts screen
        debugPrint('Navigate to shifts screen');
        break;
      case 'task_assigned':
      case 'task_updated':
        // Navigate to tasks screen
        debugPrint('Navigate to tasks screen');
        break;
      case 'announcement':
        // Navigate to announcements screen
        debugPrint('Navigate to announcements screen');
        break;
    }
  }

  /// Send notification to specific user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        debugPrint('User not found: $userId');
        return;
      }

      final fcmToken = userData['fcmToken'] as String?;
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('No FCM token for user: $userId');
        return;
      }

      // Check user's notification preferences
      if (!await _isNotificationEnabled(userId, type)) {
        debugPrint('Notifications disabled for user $userId, type: $type');
        return;
      }

      // Send notification
      await _sendNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: {
          'type': type,
          'userId': userId,
          ...additionalData ?? {},
        },
      );
    } catch (e) {
      debugPrint('Error sending notification to user: $e');
    }
  }

  /// Send notification to topic (for announcements)
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Note: In a real implementation, this would use Firebase Admin SDK
      // or a cloud function to send to topics
      debugPrint('Would send to topic: $topic - $title');
      
      // For now, we'll just log this
      // In production, you'd call your backend API to send the notification
    } catch (e) {
      debugPrint('Error sending notification to topic: $e');
    }
  }

  /// Send individual notification
  Future<void> _sendNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Note: This would typically be done via your backend/cloud functions
      // as Firebase Messaging requires admin SDK for sending
      debugPrint('Would send notification to token: $token');
      debugPrint('Title: $title, Body: $body, Data: $data');
      
      // In a real implementation, you'd call your backend API here
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// Check if notifications are enabled for user and type
  Future<bool> _isNotificationEnabled(String userId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_${userId}_$type';
      return prefs.getBool(key) ?? true; // Default to enabled
    } catch (e) {
      debugPrint('Error checking notification preferences: $e');
      return true; // Default to enabled on error
    }
  }

  /// Update notification preferences
  Future<void> updateNotificationPreference({
    required String category,
    required bool enabled,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final prefs = await SharedPreferences.getInstance();
      final key = 'notifications_${userId}_$category';
      await prefs.setBool(key, enabled);

      // Also update Firestore for backup
      await _firestore.collection('users').doc(userId).update({
        'notificationPreferences.$category': enabled,
      });

      debugPrint('Updated notification preference: $category = $enabled');
    } catch (e) {
      debugPrint('Error updating notification preference: $e');
      throw CustomException('שגיאה בעדכון העדפות התראות');
    }
  }

  /// Get notification preferences
  Future<Map<String, bool>> getNotificationPreferences() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return {};

      final prefs = await SharedPreferences.getInstance();
      
      return {
        categoryShifts: prefs.getBool('notifications_${userId}_$categoryShifts') ?? true,
        categoryTasks: prefs.getBool('notifications_${userId}_$categoryTasks') ?? true,
        categoryAnnouncements: prefs.getBool('notifications_${userId}_$categoryAnnouncements') ?? true,
      };
    } catch (e) {
      debugPrint('Error getting notification preferences: $e');
      return {
        categoryShifts: true,
        categoryTasks: true,
        categoryAnnouncements: true,
      };
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }
}