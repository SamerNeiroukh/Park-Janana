import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/services/auth_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
  });

  group('Role Management Tests', () {
    test('Owner can assign all roles', () {
      final allowedRoles = authService.getAllowedRolesToAssign('owner');
      expect(allowedRoles, contains('owner'));
      expect(allowedRoles, contains('department_manager'));
      expect(allowedRoles, contains('shift_manager'));
      expect(allowedRoles, contains('worker'));
    });

    test('Department manager can assign limited roles', () {
      final allowedRoles = authService.getAllowedRolesToAssign('department_manager');
      expect(allowedRoles, contains('shift_manager'));
      expect(allowedRoles, contains('worker'));
      expect(allowedRoles, isNot(contains('owner')));
      expect(allowedRoles, isNot(contains('department_manager')));
    });

    test('Shift manager cannot assign roles', () {
      final allowedRoles = authService.getAllowedRolesToAssign('shift_manager');
      expect(allowedRoles, isEmpty);
    });

    test('Worker cannot assign roles', () {
      final allowedRoles = authService.getAllowedRolesToAssign('worker');
      expect(allowedRoles, isEmpty);
    });

    test('Role validation works correctly', () {
      // These tests validate internal methods (we'd need to make them public or create test-specific methods)
      // For now, we test the public interface
      final ownerRoles = authService.getAllowedRolesToAssign('owner');
      final managerRoles = authService.getAllowedRolesToAssign('department_manager');
      
      expect(ownerRoles.length, 4);
      expect(managerRoles.length, 2);
    });
  });
}