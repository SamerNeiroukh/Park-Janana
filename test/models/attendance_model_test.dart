import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/models/attendance_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('AttendanceModel', () {
    test('toMap converts AttendanceModel to a map correctly', () {
      // Arrange
      final attendance = AttendanceModel(
        id: 'attendance1',
        userId: 'user1',
        userName: 'Test User',
        year: 2025,
        month: 9,
        sessions: [
          AttendanceRecord(
            clockIn: DateTime(2025, 9, 1, 9, 0),
            clockOut: DateTime(2025, 9, 1, 17, 0),
          ),
        ],
      );

      // Act
      final attendanceMap = attendance.toMap();

      // Assert
      expect(attendanceMap, {
        'userId': 'user1',
        'userName': 'Test User',
        'year': 2025,
        'month': 9,
        'sessions': [
          {
            'clockIn': Timestamp.fromDate(DateTime(2025, 9, 1, 9, 0)),
            'clockOut': Timestamp.fromDate(DateTime(2025, 9, 1, 17, 0)),
          },
        ],
      });
    });

    test('fromMap creates AttendanceModel from a map correctly', () {
      // Arrange
      final attendanceMap = {
        'userId': 'user1',
        'userName': 'Test User',
        'year': 2025,
        'month': 9,
        'sessions': [
          {
            'clockIn': Timestamp.fromDate(DateTime(2025, 9, 1, 9, 0)),
            'clockOut': Timestamp.fromDate(DateTime(2025, 9, 1, 17, 0)),
          },
        ],
      };

      // Act
      final attendance = AttendanceModel.fromMap(attendanceMap, 'attendance1');

      // Assert
      expect(attendance.id, 'attendance1');
      expect(attendance.userId, 'user1');
      expect(attendance.userName, 'Test User');
      expect(attendance.year, 2025);
      expect(attendance.month, 9);
      expect(attendance.sessions.length, 1);
      expect(attendance.sessions[0].clockIn, DateTime(2025, 9, 1, 9, 0));
      expect(attendance.sessions[0].clockOut, DateTime(2025, 9, 1, 17, 0));
    });

    test('fromMap handles missing fields gracefully', () {
      // Arrange
      final incompleteMap = {
        'userId': 'user1',
        'userName': 'Test User',
        'year': 2025,
        'month': 9,
      };

      // Act
      final attendance = AttendanceModel.fromMap(incompleteMap, 'attendance1');

      // Assert
      expect(attendance.id, 'attendance1');
      expect(attendance.userId, 'user1');
      expect(attendance.userName, 'Test User');
      expect(attendance.year, 2025);
      expect(attendance.month, 9);
      expect(attendance.sessions, []); // Default value
    });

    test('fromMap handles invalid data types gracefully', () {
      // Arrange
      final invalidMap = {
        'userId': 'user1',
        'userName': 'Test User',
        'year': 'invalid', // Invalid type
        'month': 'invalid', // Invalid type
        'sessions': 'not a list', // Invalid type
      };

      // Act
      final attendance = AttendanceModel.fromMap(invalidMap, 'attendance1');

      // Assert
      expect(attendance.id, 'attendance1');
      expect(attendance.userId, 'user1');
      expect(attendance.userName, 'Test User');
      expect(attendance.year, 0); // Default value for invalid type
      expect(attendance.month, 0); // Default value for invalid type
      expect(attendance.sessions, []); // Default value for invalid type
    });

    test('daysWorked calculates unique days correctly', () {
      // Arrange
      final attendance = AttendanceModel(
        id: 'attendance1',
        userId: 'user1',
        userName: 'Test User',
        year: 2025,
        month: 9,
        sessions: [
          AttendanceRecord(
            clockIn: DateTime(2025, 9, 1, 9, 0),
            clockOut: DateTime(2025, 9, 1, 17, 0),
          ),
          AttendanceRecord(
            clockIn: DateTime(2025, 9, 1, 18, 0),
            clockOut: DateTime(2025, 9, 1, 20, 0),
          ),
          AttendanceRecord(
            clockIn: DateTime(2025, 9, 2, 9, 0),
            clockOut: DateTime(2025, 9, 2, 17, 0),
          ),
        ],
      );

      // Act
      final daysWorked = attendance.daysWorked;

      // Assert
      expect(daysWorked, 2);
    });

    test('totalHoursWorked calculates total hours correctly', () {
      // Arrange
      final attendance = AttendanceModel(
        id: 'attendance1',
        userId: 'user1',
        userName: 'Test User',
        year: 2025,
        month: 9,
        sessions: [
          AttendanceRecord(
            clockIn: DateTime(2025, 9, 1, 9, 0),
            clockOut: DateTime(2025, 9, 1, 17, 0),
          ),
          AttendanceRecord(
            clockIn: DateTime(2025, 9, 2, 9, 0),
            clockOut: DateTime(2025, 9, 2, 17, 0),
          ),
        ],
      );

      // Act
      final totalHours = attendance.totalHoursWorked;

      // Assert
      expect(totalHours, 16.0);
    });

    test('daysWorked handles empty sessions list', () {
      // Arrange
      final attendance = AttendanceModel(
        id: 'attendance1',
        userId: 'user1',
        userName: 'Test User',
        year: 2025,
        month: 9,
        sessions: [],
      );

      // Act
      final daysWorked = attendance.daysWorked;

      // Assert
      expect(daysWorked, 0);
    });

    test('totalHoursWorked handles empty sessions list', () {
      // Arrange
      final attendance = AttendanceModel(
        id: 'attendance1',
        userId: 'user1',
        userName: 'Test User',
        year: 2025,
        month: 9,
        sessions: [],
      );

      // Act
      final totalHours = attendance.totalHoursWorked;

      // Assert
      expect(totalHours, 0.0);
    });

    test('AttendanceRecord handles invalid timestamps gracefully', () {
      // Arrange
      final invalidRecordMap = {
        'clockIn': 'invalid',
        'clockOut': 'invalid',
      };

      // Act
      final record = AttendanceRecord.fromMap(invalidRecordMap);

      // Assert
      expect(record.clockIn, isA<DateTime>()); // Should default to DateTime.now()
      expect(record.clockOut, isA<DateTime>()); // Should default to DateTime.now()
    });

    test('hoursWorked handles zero or negative durations', () {
      // Arrange
      final record = AttendanceRecord(
        clockIn: DateTime(2025, 9, 1, 17, 0),
        clockOut: DateTime(2025, 9, 1, 9, 0),
      );

      // Act
      final hoursWorked = record.hoursWorked;

      // Assert
      expect(hoursWorked, 0.0); // Should handle negative durations gracefully
    });
  });
}
