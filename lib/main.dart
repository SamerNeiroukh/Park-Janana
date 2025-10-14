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
// 🔥 Emulator imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io'; // For HTTP client to test emulator connection

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

    // 🔥 Connect to Firebase Emulators (for development only)
    if (kDebugMode) {
      await _connectToFirebaseEmulators();
    }
  } catch (e) {
    print('Error initializing Firebase or App Check: $e');
  }

  runApp(const MyApp());
}

/// 🔥 Firebase Emulator Configuration
Future<void> _connectToFirebaseEmulators() async {
  // Only connect to emulators in debug mode
  if (kDebugMode) {
    print("🔥 Connecting to Firebase Emulators...");

    // Get the appropriate host for emulators
    String host = await _getEmulatorHost();
    print("🔍 Using emulator host: $host");

    try {
      // Connect FirebaseAuth to emulator
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      print("✅ Auth Emulator connected: $host:9099");

      // Connect Firestore to emulator
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8081);
      print("✅ Firestore Emulator connected: $host:8081");

      // Connect Storage to emulator
      await FirebaseStorage.instance.useStorageEmulator(host, 9199);
      print("✅ Storage Emulator connected: $host:9199");

      print("🎉 All Firebase Emulators connected successfully!");
    } catch (e) {
      print("❌ Error connecting to emulators: $e");
    }
  } else {
    print("📱 Running in production mode - using live Firebase services");
  }
}

/// 🔍 Smart host detection for Firebase emulators
Future<String> _getEmulatorHost() async {
  // 🎯 Priority 1: Environment variable from dev script (most reliable)
  const String envHost =
      String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: '');
  if (envHost.isNotEmpty) {
    print("🔧 Using host from environment: $envHost");
    return envHost;
  }

  // 🎯 Priority 2: Platform-specific logic
  if (defaultTargetPlatform != TargetPlatform.android) {
    // Web, Desktop, iOS - always use localhost
    print("🖥️ Using localhost for non-Android platform");
    return '127.0.0.1';
  }

  // 🎯 Priority 3: Android - auto-detect or fail with instructions
  print("📱 Android platform detected, auto-detecting emulator host...");

  // For Android emulator (AVD), always use this IP
  const String emulatorHost = '10.0.2.2';
  print("🤖 Trying Android emulator host: $emulatorHost");
  if (await _testHostConnection(emulatorHost)) {
    print("✅ Connected to Android emulator host");
    return emulatorHost;
  }

  // If not Android emulator, we need the computer's real IP
  print("📱 Physical Android device detected, need computer's IP address");
  print("");
  print("❌ EMULATOR HOST NOT CONFIGURED");
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  print("");
  print("For physical Android devices, you need to:");
  print("");
  print("1️⃣  Find your computer's IP address:");
  print("   Windows: ipconfig | findstr IPv4");
  print("   Mac:     ifconfig | grep inet");
  print("   Linux:   hostname -I");
  print("");
  print("2️⃣  Use the dev script (recommended):");
  print("   Windows: .\\dev-start.ps1");
  print("   Mac/Linux: ./dev-start.sh");
  print("");
  print("3️⃣  OR set the environment variable:");
  print("   flutter run --dart-define=FIREBASE_EMULATOR_HOST=YOUR_IP");
  print("");
  print(
      "Example: flutter run --dart-define=FIREBASE_EMULATOR_HOST=192.168.1.100");
  print("");
  print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  // Return a fallback that will likely fail to make the problem obvious
  return '0.0.0.0';
}

/// 🧪 Test if a host is reachable for Firebase emulators
Future<bool> _testHostConnection(String host) async {
  try {
    // Validate host format first
    final Uri uri = Uri.parse('http://$host:9099'); // Auth emulator port
    if (uri.host.isEmpty) {
      print("❌ Invalid host format: $host");
      return false;
    }

    print("🔍 Testing emulator connection: $host:9099");

    // Try a quick HTTP request to the Auth emulator
    // This is a simple way to check if emulators are running and reachable
    try {
      final HttpClient client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      await response.drain(); // Consume the response

      client.close();

      // If we get any response (even error), emulator is reachable
      print("✅ Emulator reachable at: $host");
      return true;
    } catch (connectionError) {
      print("❌ Cannot reach emulator at: $host ($connectionError)");
      return false;
    }
  } catch (e) {
    print("❌ Error testing host $host: $e");
    return false;
  }
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.overrideAuthStream, // test-only
    this.overrideSplashDuration, // test-only
    this.overrideHomeAuthInstance, // test-only
    this.enableHomeTestMode = false, // test-only
  });

  /// If provided, used instead of FirebaseAuth.instance.authStateChanges()
  final Stream<User?>? overrideAuthStream;

  /// If provided, used instead of 6 seconds
  final Duration? overrideSplashDuration;

  /// Injected FirebaseAuth for HomeScreen (tests)
  final FirebaseAuth? overrideHomeAuthInstance;

  /// When true, HomeScreen skips async/Firebase work (tests)
  final bool enableHomeTestMode;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _showSplashScreen = true;

  @override
  void initState() {
    super.initState();

    // Show splash screen for N seconds (override-able in tests)
    final splash = widget.overrideSplashDuration ?? const Duration(seconds: 6);
    Future.delayed(splash, () {
      if (!mounted) return;
      setState(() {
        _showSplashScreen = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final authStream =
        widget.overrideAuthStream ?? FirebaseAuth.instance.authStateChanges();

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
              stream: authStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasData) {
                  return HomeScreen(
                    role: '',
                    firebaseAuth: widget.overrideHomeAuthInstance,
                    testMode: widget.enableHomeTestMode,
                  );
                }
                return const WelcomeScreen();
              },
            ),
      routes: {
        '/home': (context) => HomeScreen(
              role: '',
              firebaseAuth: widget.overrideHomeAuthInstance,
              testMode: widget.enableHomeTestMode,
            ),
        '/login': (context) => const WelcomeScreen(),
        '/profile': (context) {
          final user =
              (widget.overrideHomeAuthInstance ?? FirebaseAuth.instance)
                  .currentUser;
          if (user != null) {
            return PersonalAreaScreen(
              uid: user.uid,
              firebaseAuth:
                  widget.overrideHomeAuthInstance, // injected auth for tests
              testMode: widget.enableHomeTestMode, // minimal UI in tests
            );
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
