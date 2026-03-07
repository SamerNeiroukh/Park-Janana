import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:park_janana/core/utils/custom_exception.dart';
import 'package:park_janana/core/services/firebase_service.dart';
import 'package:park_janana/core/services/notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🟢 Create a new user with a default profile picture uploaded to Firebase
  Future<void> createUser(String email, String password, String fullName,
      String idNumber, String phoneNumber) async {
    // 🔒 First, validate that email, phone, and ID are unique
    final validation = await _firebaseService.validateUserUniqueness(
      email: email,
      phoneNumber: phoneNumber,
      idNumber: idNumber,
    );

    if (validation['emailTaken'] ?? false) {
      throw CustomException('כתובת האימייל כבר קיימת במערכת.');
    }
    if (validation['phoneTaken'] ?? false) {
      throw CustomException('מספר הטלפון כבר קיים במערכת.');
    }
    if (validation['idTaken'] ?? false) {
      throw CustomException('מספר תעודת הזהות כבר קיים במערכת.');
    }

    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String uid = userCredential.user!.uid;

      // ✅ Upload default profile picture to Firebase Storage
      final String storagePath = 'profile_pictures/$uid/profile.jpg';
      final String defaultProfilePictureUrl =
          await _uploadDefaultProfilePicture(uid);

      // ✅ Add user to Firestore with approved: false
      await _firebaseService.addUser({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'idNumber': idNumber,
        'phoneNumber': phoneNumber,
        'profile_picture': defaultProfilePictureUrl,
        'profile_picture_path': storagePath,
        'role': 'worker',
        'approved': false,
      });

      // ✅ Cache user role (UID-scoped)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole_$uid', 'worker');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw CustomException('כתובת האימייל כבר קיימת במערכת.');
      }
      throw CustomException('שגיאה ביצירת משתמש.');
    } catch (e) {
      if (e is CustomException) rethrow;
      throw CustomException('שגיאה ביצירת משתמש.');
    }
  }

  // 🟢 Upload default profile picture to Firebase Storage
  Future<String> _uploadDefaultProfilePicture(String uid) async {
    try {
      // Load the default profile image from assets as bytes
      final ByteData byteData =
          await rootBundle.load('assets/images/default_profile.png');
      final Uint8List imageData = byteData.buffer.asUint8List();

      final Reference storageRef =
          _storage.ref().child('profile_pictures/$uid/profile.jpg');

      // Upload bytes directly to Firebase Storage
      await storageRef.putData(imageData);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw CustomException('שגיאה בהעלאת תמונת פרופיל ברירת מחדל.');
    }
  }

  // 🟢 Sign in with email and password
  Future<void> signIn(String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = userCredential.user!.uid;
      final userDoc = await _firebaseService.getUser(uid);

      if (!userDoc.exists) {
        throw CustomException('מסמך המשתמש לא קיים.');
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // Check if account is approved
      final bool isApproved = data['approved'] ?? false;

      if (!isApproved) {
        // Distinguish rejected workers from those still awaiting approval.
        // For rejected accounts we keep the auth session alive so the user
        // can call reApply() (which needs an authenticated write to Firestore)
        // before we sign them out.
        if (data['rejected'] == true) {
          throw CustomException('ACCOUNT_REJECTED:$uid');
        }
        await _auth.signOut();
        throw CustomException('החשבון שלך עדיין לא אושר על ידי ההנהלה.');
      }

      // Cache user role — keyed by UID to prevent cross-account leakage
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole_$uid', data['role'] ?? 'worker');

      // Save FCM token for push notifications
      await NotificationService().saveTokenAfterLogin();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw CustomException('האימייל לא נמצא במערכת');
      } else if (e.code == 'wrong-password') {
        throw CustomException('הסיסמה שגויה');
      } else if (e.code == 'invalid-email') {
        throw CustomException('כתובת האימייל לא תקינה');
      } else if (e.code == 'too-many-requests') {
        throw CustomException(
            'יותר מדי ניסיונות התחברות. אנא נסה שוב מאוחר יותר.');
      } else {
        throw CustomException('מייל או סיסמה לא נכונים.');
      }
    } catch (e) {
      if (e is CustomException) {
        rethrow;
      }
      throw CustomException('שגיאה בהתחברות: ${e.toString()}');
    }
  }

  // 🟢 Fetch user role (Checks UID-scoped cache first)
  Future<String?> fetchUserRole(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Use UID-scoped key to prevent stale role from a different account
    final String prefKey = 'userRole_$uid';
    final String? cachedRole = prefs.getString(prefKey);

    if (cachedRole != null && cachedRole.isNotEmpty) {
      return cachedRole; // ✅ Return cached role if available
    }

    try {
      final userDoc = await _firebaseService.getUser(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;

        await prefs.setString(prefKey, role ?? ''); // ✅ Cache role
        return role;
      } else {
        throw CustomException('מסמך המשתמש לא קיים.');
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת תפקיד המשתמש.');
    }
  }

  static const Duration _profileCacheTtl = Duration(minutes: 30);

  // 🟢 Fetch user profile with default profile picture fallback (Checks Cache First)
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String prefKey = 'userProfile_$uid';
    final String tsKey = 'userProfile_ts_$uid';
    final String? cachedProfile = prefs.getString(prefKey);
    final int? cachedTs = prefs.getInt(tsKey);

    final bool cacheValid = cachedProfile != null &&
        cachedProfile.isNotEmpty &&
        cachedTs != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(cachedTs)) <
            _profileCacheTtl;

    if (cacheValid) {
      return Map<String, dynamic>.from(jsonDecode(cachedProfile));
    }

    try {
      final userDoc = await _firebaseService.getUser(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Ensure profile picture URL is present
        final String profilePicture = (data['profile_picture'] != null &&
                data['profile_picture'].isNotEmpty)
            ? data['profile_picture']
            : await _uploadDefaultProfilePicture(
                uid); // ✅ Upload default if missing

        final profileData = {
          'uid': data['uid'] ?? '',
          'email': data['email'] ?? '',
          'fullName': data['fullName'] ?? '',
          'idNumber': data['idNumber'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'profile_picture': profilePicture,
          'profile_picture_path': data['profile_picture_path'] ?? '',
          'role': data['role'] ?? '',
        };

        await prefs.setString(prefKey, jsonEncode(profileData));
        await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);

        return profileData;
      } else {
        throw CustomException('מסמך המשתמש לא קיים.');
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת פרופיל המשתמש.');
    }
  }

  // Logout (Clears Cached Data and FCM Token)
  Future<void> signOut() async {
    // Capture UID before signing out (auth.signOut() clears currentUser)
    final String? uid = _auth.currentUser?.uid;
    try {
      // Remove FCM token before signing out
      await NotificationService().removeTokenOnLogout();

      await _auth.signOut();

      // Clear cached user data on logout
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole'); // legacy unscoped key
      if (uid != null) await prefs.remove('userRole_$uid');
      await prefs.remove('userProfile'); // legacy unscoped key
      if (uid != null) await prefs.remove('userProfile_$uid');
      if (uid != null) await prefs.remove('userProfile_ts_$uid');
    } catch (e) {
      throw CustomException('שגיאה בעת התנתקות מהמערכת.');
    }
  }

  // 🟢 Update Profile Picture
  Future<void> updateProfilePicture(
      String uid, String profilePictureUrl) async {
    await _firebaseService.updateProfilePicture(uid, profilePictureUrl);

    // ✅ Update Cached Profile Picture
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String prefKey = 'userProfile_$uid';
    final String? cachedProfile = prefs.getString(prefKey);

    if (cachedProfile != null) {
      final Map<String, dynamic> profileData = jsonDecode(cachedProfile);
      profileData['profile_picture'] = profilePictureUrl;
      await prefs.setString(prefKey, jsonEncode(profileData));
    }
  }

  // 🟢 Clear User Cache (for profile updates)
  Future<void> clearUserCache() async {
    final String? uid = _auth.currentUser?.uid;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userProfile'); // legacy unscoped key
    if (uid != null) await prefs.remove('userProfile_$uid');
    if (uid != null) await prefs.remove('userProfile_ts_$uid');
  }

  // 🟢 Assign Role
  Future<void> assignRole(String uid, String role) async {
    await _firebaseService.assignRole(uid, role);

    // ✅ Update UID-scoped cached role
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole_$uid', role);
  }

  // 🟢 Re-apply for approval after rejection
  // Must be called while the user is still authenticated (before signOut).
  Future<void> reApply(String uid) async {
    try {
      await _firebaseService.updateUser(uid, {'rejected': false});
      // Sign out only after the Firestore write succeeds — if we signed out
      // first (or in finally), a write failure would leave the account marked
      // as rejected while the user has already been logged out with no
      // indication that the re-apply failed.
      await _auth.signOut();
    } catch (e) {
      throw CustomException('שגיאה בשליחת הבקשה מחדש.');
    }
  }

  // 🟢 Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw CustomException('שגיאה בשליחת קישור לאיפוס סיסמה.');
    }
  }
}
