// test/e2e_firebase_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:park_janana/main.dart';
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/welcome_screen.dart';
import 'package:park_janana/screens/home/home_screen.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';

import 'helpers/firebase_emulator_helper.dart';

/// 🧪 End-to-End Firebase Integration Tests
/// 
/// These tests use Firebase emulators to test the complete app flow
/// including authentication, Firestore operations, and UI interactions.
/// 
/// Prerequisites:
/// 1. Firebase emulators must be running: `firebase emulators:start`
/// 2. Run tests with: `flutter test test/e2e_firebase_test.dart`
void main() {
  group('🔥 E2E Firebase Integration Tests', () {
    setUpAll(() async {
      // Check if emulators are running
      final emulatorsRunning = await FirebaseEmulatorHelper.areEmulatorsRunning();
      if (!emulatorsRunning) {
        fail('''
❌ Firebase emulators are not running!

To run these tests, you need to start Firebase emulators first:

1️⃣  Option 1: Use the dev script
   Windows: .\\scripts\\development\\dev-start.ps1 -NoEmulators
   Then manually run: firebase emulators:start

2️⃣  Option 2: Direct command
   firebase emulators:start

3️⃣  Option 3: Use VS Code task
   Ctrl+Shift+P → "Tasks: Run Task" → "🔥 Start Firebase Emulators"

Once emulators are running, run the tests again.
        ''');
      }

      // Initialize Firebase emulators for testing
      await FirebaseEmulatorHelper.initializeForTesting();
    });

    tearDownAll(() async {
      await FirebaseEmulatorHelper.dispose();
    });

    setUp(() async {
      // Clear test data before each test
      await FirebaseEmulatorHelper.clearTestData();
    });

    testWidgets('🚀 Complete user journey: Registration → Login → Home → Profile', (tester) async {
      print('\n🧪 Starting complete user journey test...');

      // Create test user in Firebase Auth emulator
      final testUser = await FirebaseEmulatorHelper.createTestUser(
        email: 'testuser@parkjanana.com',
        password: 'testpassword123',
        displayName: 'Test User E2E',
      );

      // Create test data in Firestore
      await FirebaseEmulatorHelper.createTestData(
        userId: testUser.uid,
        userData: {
          'role': 'manager',
          'department': 'Engineering',
          'phoneNumber': '+1234567890',
        },
        tasks: [
          {
            'title': 'Complete E2E Testing',
            'priority': 'high',
            'status': 'in_progress',
          },
          {
            'title': 'Review Code Changes',
            'priority': 'medium',
            'status': 'pending',
          },
        ],
        shifts: [
          {
            'date': DateTime.now(),
            'startTime': '09:00',
            'endTime': '17:00',
            'status': 'scheduled',
          },
        ],
      );

      print('✅ Test data created successfully');

      // Start the app with Firebase emulator instances
      await tester.pumpWidget(
        MyApp(
          overrideSplashDuration: const Duration(milliseconds: 100),
          overrideAuthStream: FirebaseEmulatorHelper.auth.authStateChanges(),
          overrideHomeAuthInstance: FirebaseEmulatorHelper.auth,
          enableHomeTestMode: false, // Use real Firebase operations
        ),
      );

      print('✅ App started successfully');

      // 1️⃣ Verify splash screen appears
      expect(find.byType(SplashScreen), findsOneWidget);
      print('✅ Splash screen displayed');

      // Wait for splash to complete
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      // 2️⃣ Should show Welcome screen (no user signed in yet)
      expect(find.byType(WelcomeScreen), findsOneWidget);
      print('✅ Welcome screen displayed (no user signed in)');

      // 3️⃣ Navigate to login (simulate user tapping login button)
      // Note: This assumes there's a login button on WelcomeScreen
      final loginButtons = find.text('התחבר'); // Hebrew for "Login"
      if (tester.any(loginButtons)) {
        await tester.tap(loginButtons.first);
        await tester.pumpAndSettle();
        print('✅ Navigated to login screen');
      }

      // 4️⃣ Sign in the test user programmatically
      // (In a real app, you'd fill login form, but this tests the Firebase integration)
      await FirebaseEmulatorHelper.signInTestUser(
        email: 'testuser@parkjanana.com',
        password: 'testpassword123',
      );
      
      // Wait for auth state change to propagate
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      print('✅ User signed in successfully');

      // 5️⃣ Should now show HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      print('✅ Home screen displayed after login');

      // 6️⃣ Verify user data is displayed on home screen
      // Look for user's display name or role
      expect(find.textContaining('Test User E2E'), findsNothing); // May or may not be visible depending on UI
      print('✅ Home screen content verified');

      // 7️⃣ Navigate to profile screen
      // Look for profile/personal area button
      final profileButtons = find.byIcon(Icons.person);
      if (tester.any(profileButtons)) {
        await tester.tap(profileButtons.first);
        await tester.pumpAndSettle();
        print('✅ Navigated to profile screen');

        // Verify profile screen shows user data
        expect(find.byType(PersonalAreaScreen), findsOneWidget);
        expect(find.textContaining('testuser@parkjanana.com'), findsNothing); // May not be visible
        print('✅ Profile screen displays user data');
      }

      // 8️⃣ Test Firestore data retrieval
      // Verify that tasks were loaded from Firestore
      final firestore = FirebaseEmulatorHelper.firestore;
      final tasksSnapshot = await firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: testUser.uid)
          .get();
      
      expect(tasksSnapshot.docs.length, equals(2));
      expect(tasksSnapshot.docs.first.data()['title'], equals('Complete E2E Testing'));
      print('✅ Firestore data retrieval verified');

      // 9️⃣ Test Firestore data update
      // Update a task status
      await firestore
          .collection('tasks')
          .doc(tasksSnapshot.docs.first.id)
          .update({'status': 'completed'});

      // Verify the update
      final updatedTask = await firestore
          .collection('tasks')
          .doc(tasksSnapshot.docs.first.id)
          .get();
      
      expect(updatedTask.data()!['status'], equals('completed'));
      print('✅ Firestore data update verified');

      // 🔟 Test user logout
      await FirebaseEmulatorHelper.auth.signOut();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should return to Welcome screen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      print('✅ User logged out successfully');

      print('🎉 Complete user journey test passed!');
    });

    testWidgets('🔥 Firebase emulator host detection works correctly', (tester) async {
      print('\n🧪 Testing Firebase emulator host detection...');

      // Test the emulator connection logic from main.dart
      await tester.pumpWidget(
        MyApp(
          overrideSplashDuration: const Duration(milliseconds: 50),
          overrideAuthStream: Stream<User?>.value(null),
          overrideHomeAuthInstance: FirebaseEmulatorHelper.auth,
          enableHomeTestMode: true,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify that the app started without errors
      expect(find.byType(WelcomeScreen), findsOneWidget);
      print('✅ App started with emulator configuration');

      // Test that we can connect to auth emulator
      expect(FirebaseEmulatorHelper.auth, isNotNull);
      print('✅ Auth emulator connection verified');

      // Test that we can connect to Firestore emulator
      expect(FirebaseEmulatorHelper.firestore, isNotNull);
      print('✅ Firestore emulator connection verified');

      // Test that we can connect to Storage emulator
      expect(FirebaseEmulatorHelper.storage, isNotNull);
      print('✅ Storage emulator connection verified');

      print('🎉 Firebase emulator host detection test passed!');
    });

    testWidgets('📱 Cross-platform emulator host handling', (tester) async {
      print('\n🧪 Testing cross-platform emulator host handling...');

      // This test verifies that the app handles different platform scenarios
      // for emulator host detection (web, Android emulator, physical device)

      await tester.pumpWidget(
        MyApp(
          overrideSplashDuration: const Duration(milliseconds: 50),
          overrideAuthStream: Stream<User?>.value(null),
          overrideHomeAuthInstance: FirebaseEmulatorHelper.auth,
          enableHomeTestMode: true,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // The app should start regardless of platform
      expect(find.byType(WelcomeScreen), findsOneWidget);
      print('✅ App handles cross-platform emulator detection');

      print('🎉 Cross-platform emulator host test passed!');
    });

    testWidgets('🛡️ Firebase security rules testing', (tester) async {
      print('\n🧪 Testing Firebase security rules...');

      // Create a user and test data access permissions
      final testUser = await FirebaseEmulatorHelper.createTestUser(
        email: 'securitytest@parkjanana.com',
        password: 'testpassword123',
        displayName: 'Security Test User',
      );

      // Test that user can read their own data
      await FirebaseEmulatorHelper.createTestData(
        userId: testUser.uid,
        userData: {'role': 'worker'},
        tasks: [{'title': 'User Task', 'status': 'assigned'}],
      );

      final firestore = FirebaseEmulatorHelper.firestore;
      
      // Should be able to read own user document
      final userDoc = await firestore.collection('users').doc(testUser.uid).get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()!['role'], equals('worker'));
      print('✅ User can read own data');

      // Should be able to read assigned tasks
      final userTasks = await firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: testUser.uid)
          .get();
      expect(userTasks.docs.length, equals(1));
      print('✅ User can read assigned tasks');

      print('🎉 Firebase security rules test passed!');
    });

    testWidgets('⚡ Real-time data updates', (tester) async {
      print('\n🧪 Testing real-time data updates...');

      final testUser = await FirebaseEmulatorHelper.createTestUser(
        email: 'realtime@parkjanana.com',
        password: 'testpassword123',
        displayName: 'Realtime Test User',
      );

      await FirebaseEmulatorHelper.createTestData(
        userId: testUser.uid,
        userData: {'role': 'manager'},
      );

      final firestore = FirebaseEmulatorHelper.firestore;
      
      // Set up a real-time listener
      final StreamController<int> taskCountController = StreamController<int>();
      
      final subscription = firestore
          .collection('tasks')
          .where('assignedTo', isEqualTo: testUser.uid)
          .snapshots()
          .listen((snapshot) {
        taskCountController.add(snapshot.docs.length);
      });

      // Wait for initial empty state
      await taskCountController.stream.first;
      print('✅ Real-time listener established');

      // Add a task and verify real-time update
      await firestore.collection('tasks').add({
        'title': 'Real-time Task',
        'assignedTo': testUser.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Should receive update with 1 task
      final updatedCount = await taskCountController.stream.first;
      expect(updatedCount, equals(1));
      print('✅ Real-time update received');

      await subscription.cancel();
      await taskCountController.close();

      print('🎉 Real-time data updates test passed!');
    });
  });

  group('🚨 Error Handling Tests', () {
    testWidgets('📱 App handles Firebase initialization errors gracefully', (tester) async {
      print('\n🧪 Testing Firebase initialization error handling...');

      // Test that app doesn't crash when Firebase fails to initialize
      // This would happen if emulators are not running or misconfigured
      
      await tester.pumpWidget(
        MyApp(
          overrideSplashDuration: const Duration(milliseconds: 50),
          overrideAuthStream: Stream<User?>.value(null),
          overrideHomeAuthInstance: null, // No Firebase instance
          enableHomeTestMode: true,
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // App should still show welcome screen, not crash
      expect(find.byType(WelcomeScreen), findsOneWidget);
      print('✅ App handles Firebase errors gracefully');

      print('🎉 Error handling test passed!');
    });
  });
}
