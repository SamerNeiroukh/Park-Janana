import 'dart:convert';

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

  // 🟢 Create a new user with a default profile picture uploaded to Firebase
Future<void> createUser(String email, String password, String fullName, String idNumber, String phoneNumber) async {
  try {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    String uid = userCredential.user!.uid;

    // ✅ Upload default profile picture to Firebase Storage
    String defaultProfilePictureUrl = await _uploadDefaultProfilePicture(uid);

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
      File defaultImageFile = File('assets/images/default_profile.png'); // 🔹 Load the asset
      Reference storageRef = _storage.ref().child('profile_pictures/$uid/profile.jpg');

      await storageRef.putFile(defaultImageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      throw CustomException('שגיאה בהעלאת תמונת פרופיל ברירת מחדל.');
    }
  }

  // 🟢 Fetch user role (Checks Cache First)
  Future<String?> fetchUserRole(String uid) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedRole = prefs.getString('userRole');

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
    String? cachedProfile = prefs.getString('userProfile');

    if (cachedProfile != null && cachedProfile.isNotEmpty) {
      return Map<String, dynamic>.from(jsonDecode(cachedProfile)); // ✅ Return cached profile if available
    }

    try {
      final userDoc = await _firebaseService.getUser(uid);

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        // Ensure profile picture URL is present
        String profilePicture = (data['profile_picture'] != null && data['profile_picture'].isNotEmpty)
            ? data['profile_picture']
            : await _uploadDefaultProfilePicture(uid); // ✅ Upload default if missing

        final profileData = {
          'uid': data['uid'] ?? '',
          'email': data['email'] ?? '',
          'fullName': data['fullName'] ?? '',
          'idNumber': data['idNumber'] ?? '',
          'phoneNumber': data['phoneNumber'] ?? '',
          'profile_picture': profilePicture,
          'role': data['role'] ?? '',
        };

        await prefs.setString('userProfile', jsonEncode(profileData)); // ✅ Cache profile

        return profileData;
      } else {
        throw CustomException('מסמך המשתמש לא קיים.');
      }
    } catch (e) {
      throw CustomException('שגיאה בשליפת פרופיל המשתמש.');
    }
  }

  // 🟢 Logout (Clears Cached Data)
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // ✅ Clear cached user data on logout
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('userRole');
      await prefs.remove('userProfile');
    } catch (e) {
      throw CustomException('שגיאה בעת התנתקות מהמערכת.');
    }
  }

  // 🟢 Update Profile Picture
  Future<void> updateProfilePicture(String uid, String profilePictureUrl) async {
    await _firebaseService.updateProfilePicture(uid, profilePictureUrl);

    // ✅ Update Cached Profile Picture
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? cachedProfile = prefs.getString('userProfile');

    if (cachedProfile != null) {
      Map<String, dynamic> profileData = jsonDecode(cachedProfile);
      profileData['profile_picture'] = profilePictureUrl;
      await prefs.setString('userProfile', jsonEncode(profileData));
    }
  }

  // 🟢 Assign Role
  Future<void> assignRole(String uid, String role) async {
    await _firebaseService.assignRole(uid, role);

    // ✅ Update Cached Role
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userRole', role);
  }

  // 🟢 Update User Role (Enhanced for role management with validation)
  Future<void> updateUserRole(String currentUserRole, String targetUid, String newRole) async {
    // Validate if current user can perform role changes
    if (!_canManageRoles(currentUserRole)) {
      throw CustomException('אין לך הרשאה לשנות תפקידים');
    }

    // Validate if current user can assign this specific role
    if (!_canAssignRole(currentUserRole, newRole)) {
      throw CustomException('אין לך הרשאה להקצות את התפקיד הזה');
    }

    await _firebaseService.updateUserRole(targetUid, newRole);

    // Update cache if it's the current user
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? currentUid = prefs.getString('currentUid');
    if (currentUid == targetUid) {
      await prefs.setString('userRole', newRole);
    }
  }

  // 🟢 Check if user can manage roles
  bool _canManageRoles(String role) {
    return role == 'owner' || role == 'department_manager';
  }

  // 🟢 Check if user can assign specific role
  bool _canAssignRole(String currentRole, String targetRole) {
    if (currentRole == 'owner') {
      return ['department_manager', 'shift_manager', 'worker'].contains(targetRole);
    }
    if (currentRole == 'department_manager') {
      return ['shift_manager', 'worker'].contains(targetRole);
    }
    return false;
  }

  // 🟢 Get allowed roles for current user
  List<String> getAllowedRolesToAssign(String currentRole) {
    if (currentRole == 'owner') {
      return ['owner', 'department_manager', 'shift_manager', 'worker'];
    }
    if (currentRole == 'department_manager') {
      return ['shift_manager', 'worker'];
    }
    return [];
  }
}
