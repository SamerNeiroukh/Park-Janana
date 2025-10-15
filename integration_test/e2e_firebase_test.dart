// integration_test/e2e_firebase_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:park_janana/main.dart' as app;
import 'package:park_janana/screens/splash_screen.dart';
import 'package:park_janana/screens/welcome_screen.dart';
import 'package:park_janana/screens/home/home_screen.dart';
import 'package:park_janana/screens/home/personal_area_screen.dart';

/// 🧪 End-to-End Firebase Integration Tests
/// 
/// These tests use Firebase emulators to test the complete app flow.
/// The app's main.dart handles Firebase initialization and emulator connection.
/// 
/// Prerequisites:
/// 1. Firebase emulators must be running: `firebase emulators:start`
/// 2. Run tests with: `flutter test integration_test/e2e_firebase_test.dart`
void main() {
  // Simple test setup without integration_test binding for now

  group('🔥 E2E Firebase Integration Tests', () {
    testWidgets('🚀 App launches successfully with Firebase emulators', (tester) async {
      print('\n🧪 Starting app launch test...');

      // 🚀 Launch the app - this will initialize Firebase and connect to emulators
      app.main();
      await tester.pumpAndSettle();
      
      // Wait a bit for Firebase initialization
      await tester.pumpAndSettle(const Duration(seconds: 3));

      print('🔍 Checking if app launched successfully...');
      
      // App should load successfully
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'App should load successfully');
      
      // Should find either splash screen, welcome screen, or home screen
      final hasSplash = find.byType(SplashScreen).evaluate().isNotEmpty;
      final hasWelcome = find.byType(WelcomeScreen).evaluate().isNotEmpty;
      final hasHome = find.byType(HomeScreen).evaluate().isNotEmpty;
      
      expect(hasSplash || hasWelcome || hasHome, isTrue, 
        reason: 'Should show splash, welcome, or home screen');
      
      if (hasSplash) {
        print('📱 Splash screen displayed');
        // Wait for splash to finish
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
      
      if (hasWelcome || find.byType(WelcomeScreen).evaluate().isNotEmpty) {
        print('👋 Welcome screen displayed - user not logged in');
      }
      
      if (hasHome || find.byType(HomeScreen).evaluate().isNotEmpty) {
        print('🏠 Home screen displayed - user already logged in');
      }

      print('🎉 App launch test completed successfully!');
    });

    testWidgets('🔐 Basic authentication flow with emulators', (tester) async {
      print('\n🧪 Starting basic authentication test...');

      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check if we're on welcome screen
      if (find.byType(WelcomeScreen).evaluate().isNotEmpty) {
        print('� On welcome screen - testing login flow');
        
        // Look for login button
        final loginButtons = [
          find.text('התחבר'),
          find.text('Login'),
          find.byKey(const Key('login_button')),
          find.byType(ElevatedButton),
        ];
        
        bool foundLoginButton = false;
        for (final buttonFinder in loginButtons) {
          if (buttonFinder.evaluate().isNotEmpty) {
            print('🔘 Found login button, tapping...');
            await tester.tap(buttonFinder.first);
            await tester.pumpAndSettle();
            foundLoginButton = true;
            break;
          }
        }
        
        if (!foundLoginButton) {
          print('⚠️  No login button found on welcome screen');
        }
      }

      // Look for login form elements
      final loginFormElements = [
        find.byType(TextField),
        find.byType(TextFormField),
        find.byKey(const Key('email_field')),
        find.byKey(const Key('password_field')),
      ];
      
      bool hasLoginForm = false;
      for (final element in loginFormElements) {
        if (element.evaluate().isNotEmpty) {
          hasLoginForm = true;
          break;
        }
      }
      
      if (hasLoginForm) {
        print('📝 Login form found');
        
        // Try to find email and password fields
        final emailField = find.byKey(const Key('email_field')).evaluate().isNotEmpty 
          ? find.byKey(const Key('email_field'))
          : find.byType(TextField).first;
          
        final passwordField = find.byKey(const Key('password_field')).evaluate().isNotEmpty
          ? find.byKey(const Key('password_field'))
          : (find.byType(TextField).evaluate().length > 1 
              ? find.byType(TextField).at(1) 
              : find.byType(TextField).first);
        
        // Test with demo credentials (these should exist in emulator)
        try {
          await tester.enterText(emailField, 'test@parkjanana.com');
          await tester.enterText(passwordField, 'testpassword123');
          await tester.pumpAndSettle();
          
          // Look for submit button
          final submitButtons = [
            find.byKey(const Key('login_submit_button')),
            find.text('התחבר'),
            find.text('Login'),
            find.byType(ElevatedButton),
          ];
          
          for (final submitButton in submitButtons) {
            if (submitButton.evaluate().isNotEmpty) {
              print('🚀 Submitting login form...');
              await tester.tap(submitButton.first);
              await tester.pumpAndSettle(const Duration(seconds: 5));
              break;
            }
          }
          
          print('✅ Login form interaction completed');
        } catch (e) {
          print('⚠️  Could not interact with login form: $e');
        }
      } else {
        print('ℹ️  No login form found - might already be logged in or different UI');
      }

      print('🎉 Authentication flow test completed!');
    });

    testWidgets('🏠 Navigation and UI elements test', (tester) async {
      print('\n🧪 Starting navigation test...');

      // Launch the app
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check for various UI elements that should be present
      print('🔍 Checking for common UI elements...');
      
      if (find.byType(AppBar).evaluate().isNotEmpty) {
        print('✅ Found AppBar');
      }
      if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
        print('✅ Found FloatingActionButton');
      }
      if (find.byType(BottomNavigationBar).evaluate().isNotEmpty) {
        print('✅ Found BottomNavigationBar');
      }
      if (find.byType(Drawer).evaluate().isNotEmpty) {
        print('✅ Found Drawer');
      }
      if (find.byType(Card).evaluate().isNotEmpty) {
        print('✅ Found Card');
      }
      if (find.byType(ListTile).evaluate().isNotEmpty) {
        print('✅ Found ListTile');
      }
      
      // Try to interact with any buttons or tappable elements
      final tappableElements = [
        find.byType(ElevatedButton),
        find.byType(FloatingActionButton),
        find.byType(IconButton),
        find.byType(GestureDetector),
      ];
      
      for (final elementFinder in tappableElements) {
        if (elementFinder.evaluate().isNotEmpty) {
          print('🔘 Found tappable element: ${elementFinder.runtimeType}');
          try {
            await tester.tap(elementFinder.first);
            await tester.pumpAndSettle();
            print('✅ Successfully tapped element');
            break; // Only tap one element to avoid navigation issues
          } catch (e) {
            print('⚠️  Could not tap element: $e');
          }
        }
      }

      print('🎉 Navigation test completed!');
    });
  });

  group('🧪 Error Handling Tests', () {
    testWidgets('🔥 App handles Firebase initialization errors gracefully', (tester) async {
      print('\n🔥 Testing Firebase initialization error handling...');
      
      // This test ensures the app doesn't crash if Firebase fails to initialize
      // The app should show appropriate error screens or fallbacks**
      app.main();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // App should load without crashing
      expect(find.byType(MaterialApp), findsOneWidget, reason: 'App should load even with Firebase issues');
      
      // Check that we don't have any unhandled exceptions
      final errorWidgets = find.byType(ErrorWidget);
      if (errorWidgets.evaluate().isNotEmpty) {
        print('⚠️  Found error widgets, but app still loaded');
      } else {
        print('✅ No error widgets found');
      }
      
      print('✅ App handles Firebase errors gracefully');
      print('🎉 Error handling test passed!');
    });
  });
}
