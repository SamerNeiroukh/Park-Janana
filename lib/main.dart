import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ For locking orientation
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/personal_area_screen.dart';
import 'screens/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'constants/app_theme.dart';
import 'widgets/error_state_widget.dart';
import 'providers/user_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/app_state_provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  String? firebaseError;

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    firebaseError = 'לא ניתן להתחבר לשרתי האפליקציה. אנא בדוק את החיבור לאינטרנט ונסה שוב.';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: MyApp(firebaseError: firebaseError),
    ),
  );
}

class MyApp extends StatefulWidget {
  final String? firebaseError;

  const MyApp({super.key, this.firebaseError});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplashScreen = true;

  @override
  void initState() {
    super.initState();

    // Show splash screen for 6 seconds, then check login state
    Future.delayed(const Duration(seconds: 6), () {
      setState(() {
        _showSplashScreen = false;
      });
    });
  }

  void _retryApp() {
    // Restart the app by re-initializing
    // This is a simple approach - in production you might want to use a package like restart_app
    setState(() {
      _showSplashScreen = true;
    });
    // In a real app, you would re-initialize Firebase here or use a restart package
  }

  @override
  Widget build(BuildContext context) {
    // If Firebase initialization failed, show error screen immediately
    if (widget.firebaseError != null) {
      return ErrorStateWidget(
        errorMessage: widget.firebaseError!,
        onRetry: _retryApp,
      );
    }

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
