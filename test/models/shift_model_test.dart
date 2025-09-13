import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/models/shift_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FakeDocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;

  FakeDocumentSnapshot(this.id, this._data);

  Map<String, dynamic>? data() => _data;
}

void main() {
  group('ShiftModel', () {
    test('fromMap creates ShiftModel from a map correctly', () {
      // Arrange
      final shiftMap = {
        'date': '13/09/2025',
        'department': 'IT',
        'startTime': '09:00',
        'endTime': '17:00',
        'maxWorkers': 5,
        'requestedWorkers': ['user1', 'user2'],
        'assignedWorkers': ['user3'],
        'messages': [
          {'user': 'user1', 'message': 'Can I join?'}
        ],
        'createdBy': 'admin',
        'createdAt': Timestamp.fromDate(DateTime(2025, 9, 1)),
        'lastUpdatedBy': 'admin',
        'lastUpdatedAt': Timestamp.fromDate(DateTime(2025, 9, 10)),
        'status': 'active',
        'cancelReason': '',
        'shiftManager': 'manager1',
        'assignedWorkerData': [
          {'user': 'user3', 'status': 'confirmed'}
        ],
        'rejectedWorkerData': [
          {'user': 'user2', 'reason': 'Over capacity'}
        ],
      };

      // Act
      final shift = ShiftModel.fromMap('shift1', shiftMap);

      // Assert
      expect(shift.id, 'shift1');
      expect(shift.date, '13/09/2025');
      expect(shift.department, 'IT');
      expect(shift.startTime, '09:00');
      expect(shift.endTime, '17:00');
      expect(shift.maxWorkers, 5);
      expect(shift.requestedWorkers, ['user1', 'user2']);
      expect(shift.assignedWorkers, ['user3']);
      expect(shift.messages, [
        {'user': 'user1', 'message': 'Can I join?'}
      ]);
      expect(shift.createdBy, 'admin');
      expect(shift.createdAt, Timestamp.fromDate(DateTime(2025, 9, 1)));
      expect(shift.lastUpdatedBy, 'admin');
      expect(shift.lastUpdatedAt, Timestamp.fromDate(DateTime(2025, 9, 10)));
      expect(shift.status, 'active');
      expect(shift.cancelReason, '');
      expect(shift.shiftManager, 'manager1');
      expect(shift.assignedWorkerData, [
        {'user': 'user3', 'status': 'confirmed'}
      ]);
      expect(shift.rejectedWorkerData, [
        {'user': 'user2', 'reason': 'Over capacity'}
      ]);
    });

    test('toMap converts ShiftModel to a map correctly', () {
      // Arrange
      final shift = ShiftModel(
        id: 'shift1',
        date: '13/09/2025',
        department: 'IT',
        startTime: '09:00',
        endTime: '17:00',
        maxWorkers: 5,
        requestedWorkers: ['user1', 'user2'],
        assignedWorkers: ['user3'],
        messages: [
          {'user': 'user1', 'message': 'Can I join?'}
        ],
        createdBy: 'admin',
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 1)),
        lastUpdatedBy: 'admin',
        lastUpdatedAt: Timestamp.fromDate(DateTime(2025, 9, 10)),
        status: 'active',
        cancelReason: '',
        shiftManager: 'manager1',
        assignedWorkerData: [
          {'user': 'user3', 'status': 'confirmed'}
        ],
        rejectedWorkerData: [
          {'user': 'user2', 'reason': 'Over capacity'}
        ],
      );

      // Act
      final shiftMap = shift.toMap();

      // Assert
      expect(shiftMap['date'], '13/09/2025');
      expect(shiftMap['department'], 'IT');
      expect(shiftMap['startTime'], '09:00');
      expect(shiftMap['endTime'], '17:00');
      expect(shiftMap['maxWorkers'], 5);
      expect(shiftMap['requestedWorkers'], ['user1', 'user2']);
      expect(shiftMap['assignedWorkers'], ['user3']);
      expect(shiftMap['messages'], [
        {'user': 'user1', 'message': 'Can I join?'
        }
      ]);
      expect(shiftMap['createdBy'], 'admin');
      expect(shiftMap['createdAt'], Timestamp.fromDate(DateTime(2025, 9, 1)));
      expect(shiftMap['lastUpdatedBy'], 'admin');
      expect(shiftMap['lastUpdatedAt'], Timestamp.fromDate(DateTime(2025, 9, 10)));
      expect(shiftMap['status'], 'active');
      expect(shiftMap['cancelReason'], '');
      expect(shiftMap['shiftManager'], 'manager1');
      expect(shiftMap['assignedWorkerData'], [
        {'user': 'user3', 'status': 'confirmed'}
      ]);
      expect(shiftMap['rejectedWorkerData'], [
        {'user': 'user2', 'reason': 'Over capacity'}
      ]);
    });

    test('fromFirestore creates ShiftModel from a Firestore document correctly', () {
      // Arrange
      final fakeDoc = FakeDocumentSnapshot('shift1', {
        'date': '13/09/2025',
        'department': 'IT',
        'startTime': '09:00',
        'endTime': '17:00',
        'maxWorkers': 5,
        'requestedWorkers': ['user1', 'user2'],
        'assignedWorkers': ['user3'],
        'messages': [
          {'user': 'user1', 'message': 'Can I join?'}
        ],
        'createdBy': 'admin',
        'createdAt': Timestamp.fromDate(DateTime(2025, 9, 1)),
        'lastUpdatedBy': 'admin',
        'lastUpdatedAt': Timestamp.fromDate(DateTime(2025, 9, 10)),
        'status': 'active',
        'cancelReason': '',
        'shiftManager': 'manager1',
        'assignedWorkerData': [
          {'user': 'user3', 'status': 'confirmed'}
        ],
        'rejectedWorkerData': [
          {'user': 'user2', 'reason': 'Over capacity'}
        ],
      });

      // Act
      final shift = ShiftModel.fromFirestore(fakeDoc);

      // Assert
      expect(shift.id, 'shift1');
      expect(shift.date, '13/09/2025');
      expect(shift.department, 'IT');
      expect(shift.startTime, '09:00');
      expect(shift.endTime, '17:00');
      expect(shift.maxWorkers, 5);
      expect(shift.requestedWorkers, ['user1', 'user2']);
      expect(shift.assignedWorkers, ['user3']);
      expect(shift.messages, [
        {'user': 'user1', 'message': 'Can I join?'}
      ]);
      expect(shift.createdBy, 'admin');
      expect(shift.createdAt, Timestamp.fromDate(DateTime(2025, 9, 1)));
      expect(shift.lastUpdatedBy, 'admin');
      expect(shift.lastUpdatedAt, Timestamp.fromDate(DateTime(2025, 9, 10)));
      expect(shift.status, 'active');
      expect(shift.cancelReason, '');
      expect(shift.shiftManager, 'manager1');
      expect(shift.assignedWorkerData, [
        {'user': 'user3', 'status': 'confirmed'}
      ]);
      expect(shift.rejectedWorkerData, [
        {'user': 'user2', 'reason': 'Over capacity'}
      ]);
    });

    test('formattedDateWithDay returns correct format', () {
      // Arrange
      final shift = ShiftModel(
        id: 'shift1',
        date: '13/09/2025',
        department: 'IT',
        startTime: '09:00',
        endTime: '17:00',
        maxWorkers: 5,
        requestedWorkers: [],
        assignedWorkers: [],
        messages: [],
        createdBy: 'admin',
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 1)),
        lastUpdatedBy: 'admin',
        lastUpdatedAt: Timestamp.fromDate(DateTime(2025, 9, 10)),
        status: 'active',
        cancelReason: '',
        shiftManager: 'manager1',
        assignedWorkerData: [],
        rejectedWorkerData: [],
      );

      // Act
      final formattedDate = shift.formattedDateWithDay;

      // Assert
      expect(formattedDate, 'שבת, 13/09/2025');
    });

    test('isFull returns true when assignedWorkers equals maxWorkers', () {
      // Arrange
      final shift = ShiftModel(
        id: 'shift1',
        date: '13/09/2025',
        department: 'IT',
        startTime: '09:00',
        endTime: '17:00',
        maxWorkers: 1,
        requestedWorkers: [],
        assignedWorkers: ['user1'],
        messages: [],
        createdBy: 'admin',
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 1)),
        lastUpdatedBy: 'admin',
        lastUpdatedAt: Timestamp.fromDate(DateTime(2025, 9, 10)),
        status: 'active',
        cancelReason: '',
        shiftManager: 'manager1',
        assignedWorkerData: [],
        rejectedWorkerData: [],
      );

      // Act
      final isFull = shift.isFull;

      // Assert
      expect(isFull, true);
    });

    test('isUserAssigned returns true for assigned user', () {
      // Arrange
      final shift = ShiftModel(
        id: 'shift1',
        date: '13/09/2025',
        department: 'IT',
        startTime: '09:00',
        endTime: '17:00',
        maxWorkers: 5,
        requestedWorkers: [],
        assignedWorkers: ['user1'],
        messages: [],
        createdBy: 'admin',
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 1)),
        lastUpdatedBy: 'admin',
        lastUpdatedAt: Timestamp.fromDate(DateTime(2025, 9, 10)),
        status: 'active',
        cancelReason: '',
        shiftManager: 'manager1',
        assignedWorkerData: [],
        rejectedWorkerData: [],
      );

      // Act
      final isAssigned = shift.isUserAssigned('user1');

      // Assert
      expect(isAssigned, true);
    });

    test('parsedDate handles invalid date gracefully', () {
      // Arrange
      final shift = ShiftModel(
        id: 'shift1',
        date: 'invalid-date',
        department: 'IT',
        startTime: '09:00',
        endTime: '17:00',
        maxWorkers: 5,
        requestedWorkers: [],
        assignedWorkers: [],
        messages: [],
        createdBy: 'admin',
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 1)),
        lastUpdatedBy: 'admin',
        lastUpdatedAt: Timestamp.fromDate(DateTime(2025, 9, 10)),
        status: 'active',
        cancelReason: '',
        shiftManager: 'manager1',
        assignedWorkerData: [],
        rejectedWorkerData: [],
      );

      // Act
      final parsedDate = shift.parsedDate;

      // Assert
      expect(parsedDate, isA<DateTime>());
    });

    test('weekNumber calculates correct week of the year', () {
      // Arrange
      final shift = ShiftModel(
        id: 'shift1',
        date: '13/09/2025',
        department: 'IT',
        startTime: '09:00',
        endTime: '17:00',
        maxWorkers: 5,
        requestedWorkers: [],
        assignedWorkers: [],
        messages: [],
        createdBy: 'admin',
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 1)),
        lastUpdatedBy: 'admin',
        lastUpdatedAt: Timestamp.fromDate(DateTime(2025, 9, 10)),
        status: 'active',
        cancelReason: '',
        shiftManager: 'manager1',
        assignedWorkerData: [],
        rejectedWorkerData: [],
      );

      // Act
      final weekNumber = shift.weekNumber;

      // Assert
      expect(weekNumber, 37); // 13th September 2025 is in the 37th week
    });
  });
}
