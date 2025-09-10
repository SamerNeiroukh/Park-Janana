import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For locking orientation
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/personal_area_screen.dart';
import 'screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'constants/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    // Initialize Firebase
    print("firebase logs: await Firebase.initializeApp(");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // 🆕 Initialize Notification Service
    print("firebase logs: Initializing NotificationService");
    await NotificationService().initialize();
    print("firebase logs: NotificationService initialized successfully");
    
  } catch (e) {
    print('Error initializing Firebase, App Check, or NotificationService: $e');
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
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he'),
        Locale('en'),
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: child!,
        );
      },
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
