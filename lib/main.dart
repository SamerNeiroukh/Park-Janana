import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/personal_area_screen.dart';
import 'screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Initialize Firebase
    print("firebase logs: await Firebase.initializeApp(");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

   
  } catch (e) {
    print('Error initializing Firebase or App Check: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplashScreen = true;

  @override
  void initState() {
    super.initState();

    // Show splash screen for 2 seconds, then check login state
    Future.delayed(const Duration(seconds: 6), () {
      setState(() {
        _showSplashScreen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _showSplashScreen
          ? const SplashScreen()
          : StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return const HomeScreen(role: '');
                }
                return const WelcomeScreen();
              },
            ),
      routes: {
        '/home': (context) => const HomeScreen(role: ''),
        '/login': (context) => const WelcomeScreen(),
        '/profile': (context) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            return PersonalAreaScreen(uid: user.uid);
          } else {
            return const Center(
              child: Text(
                "No user is logged in. Please log in to access your profile.",
                textAlign: TextAlign.center,
              ),
            );
          }
        },
      },
    );
  }
}