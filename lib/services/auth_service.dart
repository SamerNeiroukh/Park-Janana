import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/custom_exception.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 🟢 Create a new user with default profile picture uploaded to Firebase
  Future<void> createUser(String email, String password, String fullName, String idNumber, String phoneNumber) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      // ✅ Upload default profile picture to Firebase Storage
      String defaultProfilePictureUrl = await _uploadDefaultProfilePicture(uid);

      await _firebaseService.addUser({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'idNumber': idNumber,
        'phoneNumber': phoneNumber,
        'profile_picture': defaultProfilePictureUrl, // ✅ Store Firebase Storage URL
        'role': 'worker',
      });
    } catch (e) {
      throw CustomException('שגיאה ביצירת משתמש.');
    }
  }

  // 🟢 Upload default profile picture to Firebase Storage
  Future<String> _uploadDefaultProfilePicture(String uid) async {
    try {
      File defaultImageFile = File('assets/images/default_profile.png'); // 🔹 Load the asset
      Reference storageRef = _storage.ref().child('profile_pictures/$uid/profile.jpg');

      await storageRef.putFile(defaultImageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw CustomException('שגיאה בהעלאת תמונת פרופיל ברירת מחדל.');
    }
  }

  // 🟢 Fetch user role
  Future<String?> fetchUserRole(String uid) async {
    try {
      final userDoc = await _firebaseService.getUser(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final role = data['role'] as String?;

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userRole', role ?? '');

        return role;
      } else {
        throw CustomException('מסמך המשתמש לא קיים.');
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת תפקיד המשתמש.');
    }
  }

  // 🟢 Fetch user profile with default profile picture fallback
  Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      final userDoc = await _firebaseService.getUser(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Ensure profile picture URL is present
        String profilePicture = (data['profile_picture'] != null && data['profile_picture'].isNotEmpty)
            ? data['profile_picture']
            : await _uploadDefaultProfilePicture(uid); // ✅ Upload default if missing

        return {
          'uid': data['uid'] ?? '',
          'email': data['email'] ?? '',
          'fullName': data['fullName'] ?? '',
          'idNumber': data['idNumber'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'profile_picture': profilePicture,
          'role': data['role'] ?? '',
        };
      } else {
        throw CustomException('מסמך המשתמש לא קיים.');
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת פרופיל המשתמש.');
    }
  }

  // 🟢 Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw CustomException('שגיאה בעת התנתקות מהמערכת.');
    }
  }

  // 🟢 Update Profile Picture
  Future<void> updateProfilePicture(String uid, String profilePictureUrl) async {
    await _firebaseService.updateProfilePicture(uid, profilePictureUrl);
  }

  // 🟢 Assign Role
  Future<void> assignRole(String uid, String role) async {
    await _firebaseService.assignRole(uid, role);
  }
}
