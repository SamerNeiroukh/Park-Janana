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
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final String uid = userCredential.user!.uid;

      // ✅ Upload default profile picture to Firebase Storage
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
        'role': 'worker',
        'approved': false, // 🔥 This line is required
      });

      // ✅ Cache user role
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', 'worker');
    } catch (e) {
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
        await _auth.signOut(); // Sign out immediately
        throw CustomException('החשבון שלך עדיין לא אושר על ידי ההנהלה.');
      }

      // Cache user role
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', data['role'] ?? 'worker');

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

  // 🟢 Fetch user role (Checks Cache First)
  Future<String?> fetchUserRole(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedRole = prefs.getString('userRole');

    if (cachedRole != null && cachedRole.isNotEmpty) {
      return cachedRole; // ✅ Return cached role if available
    }

    try {
      final userDoc = await _firebaseService.getUser(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;

        await prefs.setString('userRole', role ?? ''); // ✅ Cache role
        return role;
      } else {
        throw CustomException('מסמך המשתמש לא קיים.');
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת תפקיד המשתמש.');
    }
  }

  // 🟢 Fetch user profile with default profile picture fallback (Checks Cache First)
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? cachedProfile = prefs.getString('userProfile');

    if (cachedProfile != null && cachedProfile.isNotEmpty) {
      return Map<String, dynamic>.from(
          jsonDecode(cachedProfile)); // ✅ Return cached profile if available
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
          'role': data['role'] ?? '',
        };

        await prefs.setString(
            'userProfile', jsonEncode(profileData)); // ✅ Cache profile

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
    try {
      // Remove FCM token before signing out
      await NotificationService().removeTokenOnLogout();

      await _auth.signOut();

      // Clear cached user data on logout
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole');
      await prefs.remove('userProfile');
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
    final String? cachedProfile = prefs.getString('userProfile');

    if (cachedProfile != null) {
      final Map<String, dynamic> profileData = jsonDecode(cachedProfile);
      profileData['profile_picture'] = profilePictureUrl;
      await prefs.setString('userProfile', jsonEncode(profileData));
    }
  }

  // 🟢 Clear User Cache (for profile updates)
  Future<void> clearUserCache() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('userProfile');
  }

  // 🟢 Assign Role
  Future<void> assignRole(String uid, String role) async {
    await _firebaseService.assignRole(uid, role);

    // ✅ Update Cached Role
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
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
