import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_strings.dart';
import '../home/home_screen.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // ✅ Cache storage to store user roles after login
  static final Map<String, String> _userRoleCache = {};

  // Function to handle login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Sign in using email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get user UID
      String uid = userCredential.user!.uid;

      // ✅ First check if user role is cached
      if (_userRoleCache.containsKey(uid)) {
        // ✅ Use cached role instead of Firestore
        _navigateToHomeScreen(_userRoleCache[uid]!);
        return;
      }

      // Fetch user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (userDoc.exists) {
        String role = userDoc.get('role') ?? 'worker';

        // ✅ Store role in cache
        _userRoleCache[uid] = role;

        _navigateToHomeScreen(role);
      } else {
        throw Exception("User document does not exist.");
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred';
      if (e.code == 'user-not-found') {
        errorMessage = 'User not found';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password';
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ Helper function to navigate to HomeScreen
  void _navigateToHomeScreen(String role) {
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(role: role),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: AutofillGroup(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'שלום עובדים יקרים',
                  style: AppTheme.titleStyle.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'אימייל',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16.0),
                        hintText: 'הכנס את כתובת האימייל שלך',
                        hintStyle: AppTheme.hintTextStyle,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'סיסמה',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16.0),
                        hintText: 'הכנס את הסיסמה שלך',
                        hintStyle: AppTheme.hintTextStyle,
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      autofillHints: const [AutofillHints.password],
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                GestureDetector(
                  onTap: () {
                    // Handle "Forgot Password" action
                  },
                  child: Text(
                    AppStrings.forgotPassword,
                    style: AppTheme.linkTextStyle
                        .copyWith(color: AppColors.primary),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: AppTheme.primaryButtonStyle,
                        onPressed: _login,
                        child: const Text('כניסה',
                            style: AppTheme.buttonTextStyle),
                      ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('חזור', style: AppTheme.secondaryButtonTextStyle),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
