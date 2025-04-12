import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_strings.dart';
import '../home/home_screen.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/screens/auth/forgot_password_screen.dart';

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

  String? _emailError;
  String? _passwordError;

  // ✅ Cache storage to store user roles after login
  static final Map<String, String> _userRoleCache = {};

Future<void> _login() async {
  setState(() {
    _isLoading = true;
    _emailError = null;
    _passwordError = null;
  });

  try {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    String uid = userCredential.user!.uid;

    if (_userRoleCache.containsKey(uid)) {
      _navigateToHomeScreen(_userRoleCache[uid]!);
      return;
    }

    DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(uid).get();

    if (userDoc.exists) {
      String role = userDoc.get('role') ?? 'worker';
      _userRoleCache[uid] = role;
      _navigateToHomeScreen(role);
    } else {
      throw Exception("User document does not exist.");
    }
  } on FirebaseAuthException catch (e) {
    setState(() {
      if (e.code == 'user-not-found') {
        _emailError = 'האימייל לא נמצא במערכת';
      } else if (e.code == 'wrong-password') {
        _passwordError = 'הסיסמה שגויה';
      } else {
        // unexpected firebase error (e.g. invalid-email, too-many-requests)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('מייל או סיסמה לא נכונים.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('שגיאה: $e'),
      backgroundColor: Colors.red,
    ));
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


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

                /// Email
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                        hintText: 'הכנס את כתובת האימייל שלך',
                        hintStyle: AppTheme.hintTextStyle,
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        errorText: _emailError,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                /// Password
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                        hintText: 'הכנס את הסיסמה שלך',
                        hintStyle: AppTheme.hintTextStyle,
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        errorText: _passwordError,
                      ),
                      textAlign: TextAlign.center,
                      autofillHints: const [AutofillHints.password],
                    ),
                  ],
                ),

                const SizedBox(height: 16.0),

                /// Forgot Password
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
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
