import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new user
  Future<void> createUser(String email, String password, String fullName, String idNumber, String phoneNumber) async {
    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get the UID of the newly created user
      String uid = userCredential.user!.uid;

      // Save user data to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullName': fullName,
        'idNumber': idNumber,
        'phoneNumber': phoneNumber,
        'profile_picture': '', // Default empty profile picture
      });
      print("User created successfully with UID: $uid");
    } catch (e) {
      print("Error creating user: $e");
    }
  }

  // Update profile picture
  Future<void> updateProfilePicture(String uid, String profilePictureUrl) async {
    try {
      print("firebase logs: Updating profile picture for user $uid");
      await _firestore.collection('users').doc(uid).update({
        'profile_picture': profilePictureUrl,
      });
      print("firebase logs: Profile picture updated successfully for user $uid");
    } catch (e) {
      print("firebase logs: Failed to update profile picture for user $uid: $e");
      throw e;
    }
  }
}
