import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'welcome_screen.dart';

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  // Register a new user
  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new user in Firebase Authentication
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Get the UID from the newly created user
      String uid = userCredential.user!.uid;

      // Create a new user profile in Firestore
      UserModel userModel = UserModel(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        uid: uid,
        profilePicture: '', 
        role: 'worker',
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

      // Navigate back to the WelcomeScreen
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'טופס הרשמה',
              style: TextStyle(
                fontFamily: 'SuezOne',
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            _buildTextField(_fullNameController, 'שם מלא', 'הכנס את שמך המלא'),
            _buildTextField(_phoneNumberController, 'מספר טלפון', 'הכנס את מספר הטלפון שלך'),
            _buildTextField(_idNumberController, 'תעודת זהות', 'הכנס את תעודת הזהות שלך'),
            _buildTextField(_emailController, 'אימייל', 'הכנס את כתובת האימייל שלך'),
            _buildTextField(_passwordController, 'סיסמה', 'בחר סיסמה', obscureText: true),
            const SizedBox(height: 24.0),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 246, 195, 76),
                    ),
                    onPressed: _registerUser,
                    child: const Text('שלח'),
                  ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: const Text(
                'חזור',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              hintText: hint,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
