import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/screens/workers_management/user_profile_screen.dart';

void main() {
  group('User Profile Screen Widget Tests', () {
    testWidgets('UserProfileScreen displays user information correctly', (WidgetTester tester) async {
      // Mock user data
      final mockUserData = MockQueryDocumentSnapshot({
        'uid': 'test-uid',
        'fullName': 'John Doe',
        'email': 'john.doe@example.com',
        'phoneNumber': '123-456-7890',
        'idNumber': '123456789',
        'role': 'worker',
        'profile_picture': '',
      });

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(userData: mockUserData),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify user information is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.text('123-456-7890'), findsOneWidget);
      expect(find.text('123456789'), findsOneWidget);
    });

    testWidgets('Role management section is visible for authorized users', (WidgetTester tester) async {
      final mockUserData = MockQueryDocumentSnapshot({
        'uid': 'test-uid',
        'fullName': 'Manager User',
        'email': 'manager@example.com',
        'phoneNumber': '123-456-7890',
        'idNumber': '123456789',
        'role': 'shift_manager',
        'profile_picture': '',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: UserProfileScreen(userData: mockUserData),
        ),
      );

      await tester.pumpAndSettle();

      // Check if role management section exists
      expect(find.text('ניהול תפקיד'), findsWidgets);
    });
  });
}

// Mock class for testing
class MockQueryDocumentSnapshot extends QueryDocumentSnapshot {
  final Map<String, dynamic> _data;

  MockQueryDocumentSnapshot(this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  String get id => _data['uid'] ?? 'test-id';

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  bool get exists => true;

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}