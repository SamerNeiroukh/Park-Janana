import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/custom_exception.dart';
import 'firebase_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // 🟢 Create a new user
  Future<void> createUser(String email, String password, String fullName, String idNumber, String phoneNumber) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      await _firebaseService.addUser({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'idNumber': idNumber,
        'phoneNumber': phoneNumber,
        'profile_picture': '',
        'role': 'worker',
      });
    } catch (e) {
      throw CustomException('שגיאה ביצירת משתמש.');
    }
  }

  // 🟢 Update profile picture
  Future<void> updateProfilePicture(String uid, String profilePictureUrl) async {
    try {
      await _firebaseService.updateUser(uid, {'profile_picture': profilePictureUrl});
    } catch (e) {
      throw CustomException('שגיאה בעדכון תמונת הפרופיל.');
    }
  }

  // 🟢 Assign a role to a user
  Future<void> assignRole(String uid, String role) async {
    try {
      await _firebaseService.updateUser(uid, {'role': role});
    } catch (e) {
      throw CustomException('שגיאה בהקצאת תפקיד.');
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

  // 🟢 Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw CustomException('שגיאה בעת התנתקות מהמערכת.');
    }
  }
}
