import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/custom_exception.dart';
import 'notification_service.dart';

class AnnouncementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final String _collection = 'announcements';

  /// Create and send an announcement to all users
  Future<void> createAnnouncement({
    required String title,
    required String content,
    required String priority, // 'high', 'medium', 'low'
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw CustomException('משתמש לא מחובר');
      }

      // Get user info for the announcement
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();
      
      if (userData == null) {
        throw CustomException('לא נמצאו נתוני משתמש');
      }

      final senderName = userData['fullName'] ?? 'הנהלה';
      
      // Create announcement document
      final announcementData = {
        'title': title,
        'content': content,
        'priority': priority,
        'createdBy': currentUser.uid,
        'createdByName': senderName,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      // Save announcement to Firestore
      final docRef = await _firestore.collection(_collection).add(announcementData);
      
      // Send notifications to all users (via topic)
      await _notificationService.sendNotificationToTopic(
        topic: 'all_users',
        title: title,
        body: content,
        type: 'announcement',
        additionalData: {
          'announcementId': docRef.id,
          'priority': priority,
          'senderName': senderName,
        },
      );

      // Also send individual notifications to all active users as fallback
      await _sendToAllUsers(title, content, docRef.id, priority, senderName);

    } catch (e) {
      throw CustomException('שגיאה ביצירת הכרזה: $e');
    }
  }

  /// Send notification to all active users individually
  Future<void> _sendToAllUsers(
    String title, 
    String content, 
    String announcementId, 
    String priority,
    String senderName,
  ) async {
    try {
      // Get all users with FCM tokens
      final usersSnapshot = await _firestore
          .collection('users')
          .where('fcmToken', isNotEqualTo: null)
          .get();

      // Send notification to each user
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        
        await _notificationService.sendNotificationToUser(
          userId: userId,
          title: title,
          body: content,
          type: 'announcement',
          additionalData: {
            'announcementId': announcementId,
            'priority': priority,
            'senderName': senderName,
          },
        );
      }
    } catch (e) {
      // Log error but don't throw - the announcement was still created
      print('Error sending individual notifications: $e');
    }
  }

  /// Get all announcements stream
  Stream<List<Map<String, dynamic>>> getAnnouncementsStream() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  /// Mark announcement as read for a user
  Future<void> markAsRead(String announcementId, String userId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(announcementId)
          .collection('readBy')
          .doc(userId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
        'userId': userId,
      });
    } catch (e) {
      // Don't throw error for read status
      print('Error marking announcement as read: $e');
    }
  }

  /// Check if user has read announcement
  Future<bool> hasUserRead(String announcementId, String userId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(announcementId)
          .collection('readBy')
          .doc(userId)
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Delete announcement (managers only)
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection(_collection).doc(announcementId).update({
        'isActive': false,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CustomException('שגיאה במחיקת הכרזה: $e');
    }
  }

  /// Get announcement by ID
  Future<Map<String, dynamic>?> getAnnouncementById(String announcementId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(announcementId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      }
      return null;
    } catch (e) {
      throw CustomException('שגיאה בשליפת הכרזה: $e');
    }
  }
}