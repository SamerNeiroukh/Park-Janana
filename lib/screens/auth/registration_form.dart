import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../welcome_screen.dart';

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

  Future<void> _registerUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      UserModel userModel = UserModel(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        idNumber: _idNumberController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
        uid: uid,
        profilePicture: 'https://firebasestorage.googleapis.com/v0/b/park-janana-app.firebasestorage.app/o/profile_pictures%2Fdefault_profile.png?alt=media&token=918661c9-90a5-4197-8649-d2498d8ef4cd',
        role: 'worker',
      );

      await _firestore.collection('users').doc(uid).set(userModel.toMap());

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
      child: Padding(
        padding: const EdgeInsets.all(20.0), // Better spacing for UI
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('טופס הרשמה', style: AppTheme.titleStyle), // ✅ Apply theme
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
                      backgroundColor: AppColors.secondary, // ✅ Use themed color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.0),
                      ),
                    ),
                    onPressed: _registerUser,
                    child: Text('שלח', style: AppTheme.buttonTextStyle), // ✅ Apply theme
                  ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                'חזור',
                style: AppTheme.secondaryButtonTextStyle, // ✅ Use secondary button style
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
          Text(label, style: AppTheme.bodyText), // ✅ Apply body text style
          const SizedBox(height: 8.0),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration( // ✅ Use correct way to apply input decoration
              filled: AppTheme.inputDecorationTheme.filled,
              fillColor: AppTheme.inputDecorationTheme.fillColor,
              contentPadding: AppTheme.inputDecorationTheme.contentPadding,
              border: AppTheme.inputDecorationTheme.border,
              enabledBorder: AppTheme.inputDecorationTheme.enabledBorder,
              focusedBorder: AppTheme.inputDecorationTheme.focusedBorder,
              hintText: hint,
              hintStyle: AppTheme.inputDecorationTheme.hintStyle,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
