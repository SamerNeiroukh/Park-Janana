import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new user
  Future<void> createUser(String email, String password, String fullName, String idNumber, String phoneNumber) async {
  try {
    print("firebase logs: Starting user creation...");

    // Step 1: Create user in Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;
    print("firebase logs: User created successfully with UID: $uid");

    // Step 2: Save user data to Firestore
    print("firebase logs: Writing user data to Firestore for UID: $uid");
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'idNumber': idNumber,
      'phoneNumber': phoneNumber,
      'profile_picture': '',
      'role': 'worker',
    });
    print("firebase logs: User data written to Firestore successfully for UID: $uid");
  } catch (e) {
    print("firebase logs: Error during user creation or Firestore write: $e");
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

  // Assign a role to a user
  Future<void> assignRole(String uid, String role) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'role': role,
      }, SetOptions(merge: true)); // Merge ensures existing data is not overwritten
      print("Role $role assigned to user $uid successfully.");
    } catch (e) {
      print("Error assigning role: $e");
    }
  }
}
