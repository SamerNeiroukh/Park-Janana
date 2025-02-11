import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:park_janana/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/custom_exception.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new user
  Future<void> createUser(String email, String password, String fullName, String idNumber, String phoneNumber) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      String uid = userCredential.user!.uid;

      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'idNumber': idNumber,
        'phoneNumber': phoneNumber,
        'profile_picture': '',
        'role': 'worker',
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw CustomException('כתובת הדוא"ל כבר רשומה במערכת.');
      } else if (e.code == 'weak-password') {
        throw CustomException('הסיסמה חלשה מדי. נסה שוב עם סיסמה חזקה יותר.');
      } else {
        throw CustomException('אירעה שגיאה ביצירת חשבון. נסה שוב.');
      }
    } catch (e) {
      throw CustomException('שגיאה לא צפויה ביצירת חשבון.');
    }
  }

  // Update profile picture
  Future<void> updateProfilePicture(String uid, String profilePictureUrl) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).update({
        'profile_picture': profilePictureUrl,
      });
    } catch (e) {
      throw CustomException('שגיאה בעדכון תמונת הפרופיל.');
    }
  }

  // Assign a role to a user
  Future<void> assignRole(String uid, String role) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
        'role': role,
      }, SetOptions(merge: true));
    } catch (e) {
      throw CustomException('שגיאה בהקצאת תפקיד.');
    }
  }

  // Fetch User Role
  Future<String?> fetchUserRole(String uid) async {
    try {
      final DocumentSnapshot userDoc = await _firestore.collection(AppConstants.usersCollection).doc(uid).get();

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

  // Logout Function
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw CustomException('שגיאה בעת התנתקות מהמערכת.');
    }
  }
}
