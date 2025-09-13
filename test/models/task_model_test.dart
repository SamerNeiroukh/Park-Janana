import 'package:flutter_test/flutter_test.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('TaskModel', () {
    test('toMap converts TaskModel to a map correctly', () {
      // Arrange
      final task = TaskModel(
        id: 'task1',
        title: 'Test Task',
        description: 'This is a test task',
        department: 'IT',
        createdBy: 'user1',
        assignedTo: ['user2', 'user3'],
        dueDate: Timestamp.fromDate(DateTime(2025, 9, 20)),
        priority: 'high',
        status: 'in-progress',
        attachments: ['file1.png', 'file2.png'],
        comments: [
          {'user': 'user2', 'comment': 'Looks good'},
        ],
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 13)),
        workerProgress: {
          'user2': {'status': 'done', 'date': Timestamp.fromDate(DateTime(2025, 9, 15))},
        },
      );

      // Act
      final taskMap = task.toMap();

      // Assert
      expect(taskMap, {
        'title': 'Test Task',
        'description': 'This is a test task',
        'department': 'IT',
        'createdBy': 'user1',
        'assignedTo': ['user2', 'user3'],
        'dueDate': Timestamp.fromDate(DateTime(2025, 9, 20)),
        'priority': 'high',
        'status': 'in-progress',
        'attachments': ['file1.png', 'file2.png'],
        'comments': [
          {'user': 'user2', 'comment': 'Looks good'},
        ],
        'createdAt': Timestamp.fromDate(DateTime(2025, 9, 13)),
        'workerProgress': {
          'user2': {'status': 'done', 'date': Timestamp.fromDate(DateTime(2025, 9, 15))},
        },
      });
    });

    test('fromMap creates TaskModel from a map correctly', () {
      // Arrange
      final taskMap = {
        'title': 'Test Task',
        'description': 'This is a test task',
        'department': 'IT',
        'createdBy': 'user1',
        'assignedTo': ['user2', 'user3'],
        'dueDate': Timestamp.fromDate(DateTime(2025, 9, 20)),
        'priority': 'high',
        'status': 'in-progress',
        'attachments': ['file1.png', 'file2.png'],
        'comments': [
          {'user': 'user2', 'comment': 'Looks good'},
        ],
        'createdAt': Timestamp.fromDate(DateTime(2025, 9, 13)),
        'workerProgress': {
          'user2': {'status': 'done', 'date': Timestamp.fromDate(DateTime(2025, 9, 15))},
        },
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.id, 'task1');
      expect(task.title, 'Test Task');
      expect(task.description, 'This is a test task');
      expect(task.department, 'IT');
      expect(task.createdBy, 'user1');
      expect(task.assignedTo, ['user2', 'user3']);
      expect(task.dueDate, Timestamp.fromDate(DateTime(2025, 9, 20)));
      expect(task.priority, 'high');
      expect(task.status, 'in-progress');
      expect(task.attachments, ['file1.png', 'file2.png']);
      expect(task.comments, [
        {'user': 'user2', 'comment': 'Looks good'},
      ]);
      expect(task.createdAt, Timestamp.fromDate(DateTime(2025, 9, 13)));
      expect(task.workerProgress, {
        'user2': {'status': 'done', 'date': Timestamp.fromDate(DateTime(2025, 9, 15))},
      });
    });

    test('fromMap handles missing fields gracefully', () {
      // Arrange
      final incompleteMap = {
        'title': 'Test Task',
        'description': 'This is a test task',
      };

      // Act
      final task = TaskModel.fromMap('task1', incompleteMap);

      // Assert
      expect(task.id, 'task1');
      expect(task.title, 'Test Task');
      expect(task.description, 'This is a test task');
      expect(task.department, ''); // Default value
      expect(task.createdBy, ''); // Default value
      expect(task.assignedTo, []); // Default value
      expect(task.dueDate, Timestamp.fromDate(DateTime(1970, 1, 1))); // Default value
      expect(task.priority, 'low'); // Default value
      expect(task.status, 'pending'); // Default value
      expect(task.attachments, []); // Default value
      expect(task.comments, []); // Default value
      expect(task.createdAt, Timestamp.fromDate(DateTime(1970, 1, 1))); // Default value
      expect(task.workerProgress, {}); // Default value
    });

    test('fromMap parses workerProgress correctly', () {
      // Arrange
      final taskMap = {
        'title': 'Test Task',
        'description': 'This is a test task',
        'workerProgress': {
          'user1': {'status': 'in-progress', 'date': '2025-09-13'},
        },
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.workerProgress, {
        'user1': {'status': 'in-progress', 'date': '2025-09-13'},
      });
    });
  });
}
