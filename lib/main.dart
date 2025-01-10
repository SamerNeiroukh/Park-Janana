import 'package:flutter/material.dart';
    
import 'package:firebase_core/firebase_core.dart';
    

  
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/personal_area_screen.dart';
    
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {
        '/home': (context) => const HomeScreen(role: '',),
        '/profile': (context) {
          // Check if the user is logged in before navigating to the profile
    print("firebase logs: final user = FirebaseAuth.instance.currentUser;");
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