import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'core/providers/locale_provider.dart';
import 'features/home/screens/splash_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/home/screens/personal_area_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'core/constants/app_theme.dart';
import 'core/widgets/error_state_widget.dart';
import 'core/services/notification_service.dart';
import 'core/widgets/network_banner.dart';
import 'features/home/providers/user_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/home/providers/app_state_provider.dart';
import 'features/home/providers/home_badge_provider.dart';

/// Global navigator key for notification deep linking.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
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

    // Set up background message handler for FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Enable Firestore offline persistence with explicit config
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 50 * 1024 * 1024, // 50 MB cache
    );

    // Initialize notification service
    await NotificationService().initialize();

    // Respect user's crash-reporting opt-out preference (default: enabled).
    // The setting is toggled from Settings → "שלח דוחות קריסה".
    final prefs = await SharedPreferences.getInstance();
    final crashlyticsEnabled = prefs.getBool('crashlytics_enabled') ?? true;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(crashlyticsEnabled);
    if (crashlyticsEnabled) {
      // Route all Flutter framework errors to Crashlytics
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Route async/platform errors that Flutter doesn't catch
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    firebaseError =
        'לא ניתן להתחבר לשרתי האפליקציה. אנא בדוק את החיבור לאינטרנט ונסה שוב.';
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => HomeBadgeProvider()),
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
      if (mounted) {
        setState(() {
          _showSplashScreen = false;
        });
      }
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

    final locale = context.watch<LocaleProvider>().locale;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: LocaleProvider.supportedLocales,
      builder: (context, child) {
        return Stack(
          children: [
            child!,
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NetworkBanner(),
            ),
          ],
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
                  return const HomeScreen();
                }
                return const WelcomeScreen();
              },
            ),
      routes: {
        '/home': (context) => const HomeScreen(),
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
