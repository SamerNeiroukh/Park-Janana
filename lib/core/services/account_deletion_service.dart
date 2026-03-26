import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/services/biometric_service.dart';
import 'package:park_janana/core/services/notification_service.dart';

/// Permanently deletes the current user's account and all associated personal
/// data. Attendance, shift, and task records are preserved as business records
/// but are naturally anonymised once the user document is removed.
///
/// Required by Apple App Store Review Guideline 5.1.1 (Data Collection and
/// Storage) — apps that support account creation must provide a way to delete
/// the account and all associated data.
class AccountDeletionService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// Re-authenticates the user with [password], then permanently deletes:
  ///   1. FCM tokens (Firestore + local cache)
  ///   2. Profile photo from Firebase Storage
  ///   3. Notifications subcollection from Firestore
  ///   4. User document from Firestore
  ///   5. All locally-cached SharedPreferences data
  ///   6. Biometric credentials from Keychain
  ///   7. Firebase Auth account (must be last)
  ///
  /// Throws on any critical failure so the caller can display an error.
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('לא נמצא משתמש מחובר');
    }

    // Step 1 — Re-authenticate.
    // Firebase requires recent authentication before sensitive operations
    // such as account deletion. This also serves as the user's password
    // confirmation before the irreversible deletion.
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;

    // Step 2 — Remove FCM push notification token and cancel local alerts.
    // Failures are swallowed — the token will expire naturally.
    try {
      await NotificationService().removeTokenOnLogout();
    } catch (_) {}

    // Step 3 — Delete profile picture from Firebase Storage.
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      final picturePath =
          userDoc.data()?['profile_picture_path'] as String?;
      if (picturePath != null && picturePath.isNotEmpty) {
        await _storage.ref(picturePath).delete();
      }
    } catch (_) {}

    // Step 4 — Delete notifications subcollection (batch for efficiency).
    try {
      final notifSnap = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('notifications')
          .get();
      if (notifSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in notifSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (_) {}

    // Step 5 — Delete the main user Firestore document.
    // This is the primary personal data record.
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();

    // Step 6 — Clear all locally-cached SharedPreferences data.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole_$uid');
      await prefs.remove('userProfile_$uid');
      await prefs.remove('userProfile_ts_$uid');
      await prefs.remove('fcm_last_token_$uid');
      await prefs.remove('notifications_enabled');
      await prefs.remove('crashlytics_enabled');
      await prefs.remove('notification_permission_requested');
    } catch (_) {}

    // Step 7 — Clear biometric credentials from the iOS Keychain.
    try {
      await BiometricService().clearCredentials();
    } catch (_) {}

    // Step 8 — Delete the Firebase Auth account.
    // Must be the very last step — once deleted, no further Firestore or
    // Storage operations on behalf of this UID are possible.
    await user.delete();
  }
}
