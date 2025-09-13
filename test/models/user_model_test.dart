import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('toMap converts UserModel to a map correctly', () {
      // Arrange
      final user = UserModel(
        uid: '123',
        email: 'test@example.com',
        fullName: 'Test User',
        idNumber: '987654321',
        phoneNumber: '1234567890',
        profilePicture: 'profile.png',
        role: 'admin',
        licensedDepartments: ['HR', 'IT'],
      );

      // Act
      final userMap = user.toMap();

      // Assert
      expect(userMap, {
        'uid': '123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'idNumber': '987654321',
        'phoneNumber': '1234567890',
        'profile_picture': 'profile.png',
        'role': 'admin',
        'licensedDepartments': ['HR', 'IT'],
      });
    });

    test('fromMap creates UserModel from a map correctly', () {
      // Arrange
      final userMap = {
        'uid': '123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'idNumber': '987654321',
        'phoneNumber': '1234567890',
        'profile_picture': 'profile.png',
        'role': 'admin',
        'licensedDepartments': ['HR', 'IT'],
      };

      // Act
      final user = UserModel.fromMap(userMap);

      // Assert
      expect(user.uid, '123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, 'Test User');
      expect(user.idNumber, '987654321');
      expect(user.phoneNumber, '1234567890');
      expect(user.profilePicture, 'profile.png');
      expect(user.role, 'admin');
      expect(user.licensedDepartments, ['HR', 'IT']);
    });

    test('UserModel initializes with default values', () {
      // Arrange & Act
      final user = UserModel(
        uid: '123',
        email: 'test@example.com',
        fullName: 'Test User',
        idNumber: '987654321',
        phoneNumber: '1234567890',
        profilePicture: 'profile.png',
        role: 'admin',
      );

      // Assert
      expect(user.licensedDepartments, []); // Default value
    });

    test('fromMap handles missing fields gracefully', () {
      // Arrange
      final incompleteMap = {
        'uid': '123',
        'email': 'test@example.com',
      };

      // Act
      final user = UserModel.fromMap(incompleteMap);

      // Assert
      expect(user.uid, '123');
      expect(user.email, 'test@example.com');
      expect(user.fullName, ''); // Default value
      expect(user.idNumber, ''); // Default value
      expect(user.phoneNumber, ''); // Default value
      expect(user.profilePicture, ''); // Default value
      expect(user.role, 'worker'); // Default value
      expect(user.licensedDepartments, []); // Default value
    });
  });
}
