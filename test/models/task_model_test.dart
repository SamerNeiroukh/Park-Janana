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
          'user2': {
            'status': 'done',
            'date': Timestamp.fromDate(DateTime(2025, 9, 15))
          },
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
          'user2': {
            'status': 'done',
            'date': Timestamp.fromDate(DateTime(2025, 9, 15))
          },
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
          'user2': {
            'status': 'done',
            'date': Timestamp.fromDate(DateTime(2025, 9, 15))
          },
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
        'user2': {
          'status': 'done',
          'date': Timestamp.fromDate(DateTime(2025, 9, 15))
        },
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
      expect(task.dueDate,
          Timestamp.fromDate(DateTime(1970, 1, 1))); // Default value
      expect(task.priority, 'low'); // Default value
      expect(task.status, 'pending'); // Default value
      expect(task.attachments, []); // Default value
      expect(task.comments, []); // Default value
      expect(task.createdAt,
          Timestamp.fromDate(DateTime(1970, 1, 1))); // Default value
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

    test('fromMap handles invalid workerProgress gracefully', () {
      // Arrange
      final taskMap = {
        'title': 'Test Task',
        'description': 'This is a test task',
        'workerProgress': 'invalid', // Invalid format
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.workerProgress, {}); // Should default to an empty map
    });

    test('fromMap handles empty fields correctly', () {
      // Arrange
      final taskMap = {
        'title': '',
        'description': '',
        'assignedTo': [],
        'attachments': [],
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.title, '');
      expect(task.description, '');
      expect(task.assignedTo, []);
      expect(task.attachments, []);
    });

    test('toMap includes all fields correctly', () {
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
          'user2': {
            'status': 'done',
            'date': Timestamp.fromDate(DateTime(2025, 9, 15))
          },
        },
      );

      // Act
      final taskMap = task.toMap();

      // Assert
      expect(taskMap['title'], 'Test Task');
      expect(taskMap['description'], 'This is a test task');
      expect(taskMap['department'], 'IT');
      expect(taskMap['createdBy'], 'user1');
      expect(taskMap['assignedTo'], ['user2', 'user3']);
      expect(taskMap['dueDate'], Timestamp.fromDate(DateTime(2025, 9, 20)));
      expect(taskMap['priority'], 'high');
      expect(taskMap['status'], 'in-progress');
      expect(taskMap['attachments'], ['file1.png', 'file2.png']);
      expect(taskMap['comments'], [
        {'user': 'user2', 'comment': 'Looks good'},
      ]);
      expect(taskMap['createdAt'], Timestamp.fromDate(DateTime(2025, 9, 13)));
      expect(taskMap['workerProgress'], {
        'user2': {
          'status': 'done',
          'date': Timestamp.fromDate(DateTime(2025, 9, 15))
        },
      });
    });

    test('fromMap handles unexpected data types gracefully', () {
      // Arrange
      final invalidMap = {
        'title': 123, // Invalid type
        'description': true, // Invalid type
        'assignedTo': 'not a list', // Invalid type
        'dueDate': 'not a timestamp', // Invalid type
      };

      // Act
      final task = TaskModel.fromMap('task1', invalidMap);

      // Assert
      expect(task.title, ''); // Default value
      expect(task.description, ''); // Default value
      expect(task.assignedTo, []); // Default value
      expect(task.dueDate,
          Timestamp.fromDate(DateTime(1970, 1, 1))); // Default value
    });

    test('workerProgress handles multiple users correctly', () {
      // Arrange
      final taskMap = {
        'workerProgress': {
          'user1': {'status': 'in-progress', 'date': '2025-09-13'},
          'user2': {'status': 'done', 'date': '2025-09-14'},
        },
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.workerProgress, {
        'user1': {'status': 'in-progress', 'date': '2025-09-13'},
        'user2': {'status': 'done', 'date': '2025-09-14'},
      });
    });

    test('fromMap handles boundary values correctly', () {
      // Arrange
      final taskMap = {
        'title': 'A' * 1000, // Very long string
        'description': 'B' * 1000,
        'dueDate': Timestamp.fromDate(DateTime(9999, 12, 31)), // Extreme future date
        'createdAt': Timestamp.fromDate(DateTime(1970, 1, 1)), // Valid fallback date
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.title, 'A' * 1000);
      expect(task.description, 'B' * 1000);
      expect(task.dueDate, Timestamp.fromDate(DateTime(9999, 12, 31)));
      expect(task.createdAt, Timestamp.fromDate(DateTime(1970, 1, 1)));
    });

    test('fromMap handles invalid data types gracefully', () {
      // Arrange
      final taskMap = {
        'title': 123, // Invalid type
        'description': true, // Invalid type
        'assignedTo': 'not a list', // Invalid type
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.title, ''); // Default value
      expect(task.description, ''); // Default value
      expect(task.assignedTo, []); // Default value
    });

    test('fromMap handles null fields correctly', () {
      // Arrange
      final taskMap = {
        'title': null,
        'description': null,
        'assignedTo': null,
      };

      // Act
      final task = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(task.title, ''); // Default value
      expect(task.description, ''); // Default value
      expect(task.assignedTo, []); // Default value
    });

    test('toMap and fromMap maintain consistency', () {
      // Arrange
      final task = TaskModel(
        id: 'task1',
        title: 'Consistency Test',
        description: 'Testing serialization consistency',
        department: 'QA',
        createdBy: 'user1',
        assignedTo: ['user2'],
        dueDate: Timestamp.fromDate(DateTime(2025, 9, 20)),
        priority: 'medium',
        status: 'open',
        attachments: ['file1.png'],
        comments: [
          {'user': 'user2', 'comment': 'Looks good'},
        ],
        createdAt: Timestamp.fromDate(DateTime(2025, 9, 13)),
        workerProgress: {
          'user2': {
            'status': 'in-progress',
            'date': Timestamp.fromDate(DateTime(2025, 9, 15))
          },
        },
      );

      // Act
      final taskMap = task.toMap();
      final recreatedTask = TaskModel.fromMap('task1', taskMap);

      // Assert
      expect(recreatedTask.id, task.id);
      expect(recreatedTask.title, task.title);
      expect(recreatedTask.description, task.description);
      expect(recreatedTask.department, task.department);
      expect(recreatedTask.createdBy, task.createdBy);
      expect(recreatedTask.assignedTo, task.assignedTo);
      expect(recreatedTask.dueDate, task.dueDate);
      expect(recreatedTask.priority, task.priority);
      expect(recreatedTask.status, task.status);
      expect(recreatedTask.attachments, task.attachments);
      expect(recreatedTask.comments, task.comments);
      expect(recreatedTask.createdAt, task.createdAt);
      expect(recreatedTask.workerProgress, task.workerProgress);
    });
  });
}
