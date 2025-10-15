// test/helpers/firebase_emulator_helper.dart
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// 🔥 Firebase Emulator Helper for Testing
/// Provides utilities for connecting to and managing Firebase emulators during tests
class FirebaseEmulatorHelper {
  static const String _emulatorHost = '127.0.0.1';
  static const int _authPort = 9099;
  static const int _firestorePort = 8081;
  static const int _storagePort = 9199;

  static bool _isInitialized = false;
  static FirebaseApp? _testApp;

  /// Initialize Firebase with emulator connection for testing
  static Future<void> initializeForTesting({
    String projectId = 'park-janana-test',
  }) async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase with test configuration
      _testApp = await Firebase.initializeApp(
        name: 'test-app',
        options: FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: '123456789',
          projectId: projectId,
        ),
      );

      // Connect to emulators
      await _connectToEmulators();
      _isInitialized = true;

      print('🧪 Firebase emulators initialized for testing');
    } catch (e) {
      print('❌ Failed to initialize Firebase emulators for testing: $e');
      rethrow;
    }
  }

  /// Connect all Firebase services to emulators
  static Future<void> _connectToEmulators() async {
    try {
      // Connect Auth emulator
      await FirebaseAuth.instanceFor(app: _testApp!)
          .useAuthEmulator(_emulatorHost, _authPort);
      print('✅ Test Auth Emulator connected: $_emulatorHost:$_authPort');

      // Connect Firestore emulator
      FirebaseFirestore.instanceFor(app: _testApp!)
          .useFirestoreEmulator(_emulatorHost, _firestorePort);
      print('✅ Test Firestore Emulator connected: $_emulatorHost:$_firestorePort');

      // Connect Storage emulator
      await FirebaseStorage.instanceFor(app: _testApp!)
          .useStorageEmulator(_emulatorHost, _storagePort);
      print('✅ Test Storage Emulator connected: $_emulatorHost:$_storagePort');
    } catch (e) {
      print('❌ Error connecting to emulators: $e');
      rethrow;
    }
  }

  /// Get Firebase Auth instance for testing
  static FirebaseAuth get auth {
    if (!_isInitialized || _testApp == null) {
      throw StateError('Firebase emulators not initialized. Call initializeForTesting() first.');
    }
    return FirebaseAuth.instanceFor(app: _testApp!);
  }

  /// Get Firestore instance for testing
  static FirebaseFirestore get firestore {
    if (!_isInitialized || _testApp == null) {
      throw StateError('Firebase emulators not initialized. Call initializeForTesting() first.');
    }
    return FirebaseFirestore.instanceFor(app: _testApp!);
  }

  /// Get Firebase Storage instance for testing
  static FirebaseStorage get storage {
    if (!_isInitialized || _testApp == null) {
      throw StateError('Firebase emulators not initialized. Call initializeForTesting() first.');
    }
    return FirebaseStorage.instanceFor(app: _testApp!);
  }

  /// Create a test user in the Auth emulator
  static Future<User> createTestUser({
    String email = 'test@parkjanana.com',
    String password = 'testpassword123',
    String displayName = 'Test User',
  }) async {
    final authInstance = auth;
    
    try {
      final userCredential = await authInstance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user!.updateDisplayName(displayName);
      await userCredential.user!.reload();
      
      print('✅ Test user created: $email');
      return userCredential.user!;
    } catch (e) {
      print('❌ Failed to create test user: $e');
      rethrow;
    }
  }

  /// Sign in a test user
  static Future<User> signInTestUser({
    String email = 'test@parkjanana.com',
    String password = 'testpassword123',
  }) async {
    final authInstance = auth;
    
    try {
      final userCredential = await authInstance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Test user signed in: $email');
      return userCredential.user!;
    } catch (e) {
      print('❌ Failed to sign in test user: $e');
      rethrow;
    }
  }

  /// Create test data in Firestore
  static Future<void> createTestData({
    required String userId,
    Map<String, dynamic>? userData,
    List<Map<String, dynamic>>? tasks,
    List<Map<String, dynamic>>? shifts,
  }) async {
    final firestoreInstance = firestore;
    
    try {
      // Create user document
      if (userData != null) {
        await firestoreInstance.collection('users').doc(userId).set({
          'email': 'test@parkjanana.com',
          'displayName': 'Test User',
          'role': 'manager',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          ...userData,
        });
        print('✅ Test user data created in Firestore');
      }

      // Create test tasks
      if (tasks != null) {
        final batch = firestoreInstance.batch();
        for (int i = 0; i < tasks.length; i++) {
          final taskRef = firestoreInstance.collection('tasks').doc();
          batch.set(taskRef, {
            'title': 'Test Task ${i + 1}',
            'description': 'This is a test task for e2e testing',
            'assignedTo': userId,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'dueDate': DateTime.now().add(Duration(days: 1)),
            ...tasks[i],
          });
        }
        await batch.commit();
        print('✅ Test tasks created in Firestore');
      }

      // Create test shifts
      if (shifts != null) {
        final batch = firestoreInstance.batch();
        for (int i = 0; i < shifts.length; i++) {
          final shiftRef = firestoreInstance.collection('shifts').doc();
          batch.set(shiftRef, {
            'userId': userId,
            'date': DateTime.now().add(Duration(days: i)),
            'startTime': '09:00',
            'endTime': '17:00',
            'status': 'scheduled',
            'createdAt': FieldValue.serverTimestamp(),
            ...shifts[i],
          });
        }
        await batch.commit();
        print('✅ Test shifts created in Firestore');
      }
    } catch (e) {
      print('❌ Failed to create test data: $e');
      rethrow;
    }
  }

  /// Clear all test data from emulators
  static Future<void> clearTestData() async {
    if (!_isInitialized) return;

    try {
      final firestoreInstance = firestore;
      
      // Clear users collection
      final users = await firestoreInstance.collection('users').get();
      for (var doc in users.docs) {
        await doc.reference.delete();
      }

      // Clear tasks collection
      final tasks = await firestoreInstance.collection('tasks').get();
      for (var doc in tasks.docs) {
        await doc.reference.delete();
      }

      // Clear shifts collection
      final shifts = await firestoreInstance.collection('shifts').get();
      for (var doc in shifts.docs) {
        await doc.reference.delete();
      }

      // Sign out current user
      await auth.signOut();
      
      print('🧹 Test data cleared from emulators');
    } catch (e) {
      print('❌ Failed to clear test data: $e');
    }
  }

  /// Check if Firebase emulators are running
  static Future<bool> areEmulatorsRunning() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 2);

      // Test Auth emulator
      final authRequest = await client.getUrl(Uri.parse('http://$_emulatorHost:$_authPort'));
      final authResponse = await authRequest.close();
      await authResponse.drain();

      // Test Firestore emulator
      final firestoreRequest = await client.getUrl(Uri.parse('http://$_emulatorHost:$_firestorePort'));
      final firestoreResponse = await firestoreRequest.close();
      await firestoreResponse.drain();

      client.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clean up and dispose resources
  static Future<void> dispose() async {
    if (_isInitialized) {
      await clearTestData();
      if (_testApp != null) {
        await _testApp!.delete();
        _testApp = null;
      }
      _isInitialized = false;
      print('🧪 Firebase emulator helper disposed');
    }
  }
}
