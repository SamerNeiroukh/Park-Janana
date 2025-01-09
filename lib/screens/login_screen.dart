import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Function to handle login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Sign in using email and password
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Navigate to the home screen upon success
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'שגיאה התרחשה';
      if (e.code == 'user-not-found') {
        errorMessage = 'משתמש לא נמצא';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'סיסמה שגויה';
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        _isLoading = false;
      });
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
                const Text(
                  'שלום עובדים יקרים',
                  style: TextStyle(
                    fontFamily: 'SuezOne',
                    fontSize: 36.0,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 86, 194, 244),
                  ),
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                        hintText: 'הכנס את כתובת האימייל שלך',
                        hintStyle: const TextStyle(fontSize: 14.0),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 86, 194, 244),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
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
                        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
                        hintText: 'הכנס את הסיסמה שלך',
                        hintStyle: const TextStyle(fontSize: 14.0),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 86, 194, 244),
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
                  child: const Text(
                    'שכחתי סיסמה',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Color.fromARGB(255, 86, 194, 244),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 86, 194, 244),
                          elevation: 4,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'כניסה',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
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
        ),
      ),
    );
  }
}
