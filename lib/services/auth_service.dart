import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user with email and password
  Future<User?> registerUser({
    required String email,
    required String password,
    required UserModel userModel,
  }) async {
    try {
      // Create user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user details in Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid) // Use Firebase-generated UID as the document ID
          .set(userModel.toMap());

      return userCredential.user;
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Login user with email and password
  Future<User?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } catch (e) {
      print('Error logging in: $e');
      rethrow;
    }
  }
}
