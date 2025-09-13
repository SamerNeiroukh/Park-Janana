import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/models/shift_model.dart';
import 'package:park_janana/models/task_model.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ReportService {
  /// Get all shifts that the worker was involved in (even if removed) in a specific month
  static Future<List<ShiftModel>> getShiftsForWorkerByMonth({
    required String userId,
    required DateTime month,
  }) async {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    final snapshot = await FirebaseFirestore.instance
        .collection('shifts')
        .get(); // Removed server-side filter for full inclusion

    final List<ShiftModel> relevantShifts = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final shiftDateStr = data['date']; // Expected format: dd/MM/yyyy

      try {
        final parts = shiftDateStr.split('/');
        final parsedDate = DateTime.parse('${parts[2]}-${parts[1]}-${parts[0]}');

        if (parsedDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            parsedDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
          
          final assignedData = List<Map<String, dynamic>>.from(data['assignedWorkerData'] ?? []);
          final wasInvolved = assignedData.any((d) => d['userId'] == userId);

          if (wasInvolved) {
            relevantShifts.add(
              ShiftModel(
                id: doc.id,
                date: data['date'] ?? '',
                department: data['department'] ?? '',
                startTime: data['startTime'] ?? '',
                endTime: data['endTime'] ?? '',
                maxWorkers: data['maxWorkers'] ?? 0,
                requestedWorkers: List<String>.from(data['requestedWorkers'] ?? []),
                assignedWorkers: List<String>.from(data['assignedWorkers'] ?? []),
                messages: List<Map<String, dynamic>>.from(data['messages'] ?? []),
                createdBy: data['createdBy'] ?? '',
                lastUpdatedBy: data['lastUpdatedBy'] ?? '',
                status: data['status'] ?? '',
                cancelReason: data['cancelReason'] ?? '',
                createdAt: data['createdAt'],
                lastUpdatedAt: data['lastUpdatedAt'],
                assignedWorkerData: assignedData,
                rejectedWorkerData: List<Map<String, dynamic>>.from(data['rejectedWorkerData'] ?? []),
                shiftManager: data['shiftManager'] ?? '',
              ),
            );
          }
        }
      } catch (e) {
        continue; // Skip invalid dates
      }
    }

    return relevantShifts;
  }

  /// Get tasks filtered by department, status, and date range
  static Future<List<TaskModel>> getTasksByFilters({
    String? department,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = FirebaseFirestore.instance.collection('tasks');

      // Apply department filter
      if (department != null && department.isNotEmpty) {
        query = query.where('department', isEqualTo: department);
      }

      // Apply status filter
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }

      // Apply date range filter
      if (startDate != null) {
        query = query.where('dueDate', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('dueDate', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => TaskModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching filtered tasks: $e');
      return [];
    }
  }

  /// Get shift summary statistics by department and status
  static Future<Map<String, Map<String, int>>> getShiftSummaryByDepartment({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('shifts').get();
      final Map<String, Map<String, int>> summary = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final shiftDateStr = data['date']; // Format: dd/MM/yyyy
        final department = data['department'] ?? 'Unknown';
        final status = data['status'] ?? 'active';

        // Parse date and apply date filter if provided
        if (startDate != null || endDate != null) {
          try {
            final parts = shiftDateStr.split('/');
            final parsedDate = DateTime.parse('${parts[2]}-${parts[1]}-${parts[0]}');
            
            if (startDate != null && parsedDate.isBefore(startDate)) continue;
            if (endDate != null && parsedDate.isAfter(endDate)) continue;
          } catch (e) {
            continue; // Skip invalid dates
          }
        }

        // Determine shift status (open/filled/cancelled)
        final maxWorkers = data['maxWorkers'] ?? 0;
        final assignedWorkers = List<String>.from(data['assignedWorkers'] ?? []);
        
        String shiftStatus;
        if (status == 'cancelled') {
          shiftStatus = 'cancelled';
        } else if (assignedWorkers.length >= maxWorkers && maxWorkers > 0) {
          shiftStatus = 'filled';
        } else {
          shiftStatus = 'open';
        }

        // Initialize department summary if not exists
        if (!summary.containsKey(department)) {
          summary[department] = {
            'open': 0,
            'filled': 0,
            'cancelled': 0,
            'total': 0,
            'assigned_count': 0,
          };
        }

        // Update counts
        summary[department]![shiftStatus] = (summary[department]![shiftStatus] ?? 0) + 1;
        summary[department]!['total'] = (summary[department]!['total'] ?? 0) + 1;
        summary[department]!['assigned_count'] = (summary[department]!['assigned_count'] ?? 0) + assignedWorkers.length;
      }

      return summary;
    } catch (e) {
      print('Error generating shift summary: $e');
      return {};
    }
  }

  /// Export task data to Excel
  static Future<String?> exportTasksToExcel(List<TaskModel> tasks, String fileName) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Tasks'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('משימה');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('תיאור');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('מחלקה');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('סטטוס');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('עדיפות');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('תאריך יעד');
      sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue('נוצר על ידי');

      // Add data rows
      for (int i = 0; i < tasks.length; i++) {
        final task = tasks[i];
        final rowIndex = i + 2;
        
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue(task.title);
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = TextCellValue(task.description);
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value = TextCellValue(task.department);
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value = TextCellValue(task.status);
        sheet.cell(CellIndex.indexByString('E$rowIndex')).value = TextCellValue(task.priority);
        
        final dueDate = task.dueDate.toDate();
        sheet.cell(CellIndex.indexByString('F$rowIndex')).value = TextCellValue(DateFormat('dd/MM/yyyy').format(dueDate));
        sheet.cell(CellIndex.indexByString('G$rowIndex')).value = TextCellValue(task.createdBy);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      print('Error exporting tasks to Excel: $e');
      return null;
    }
  }

  /// Export shift summary to Excel
  static Future<String?> exportShiftSummaryToExcel(Map<String, Map<String, int>> summary, String fileName) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Shift Summary'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('מחלקה');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('פתוחות');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('מלאות');
      sheet.cell(CellIndex.indexByString('D1')).value = TextCellValue('מבוטלות');
      sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('סה״כ');
      sheet.cell(CellIndex.indexByString('F1')).value = TextCellValue('עובדים מוקצים');

      // Add data rows
      int rowIndex = 2;
      summary.forEach((department, stats) {
        sheet.cell(CellIndex.indexByString('A$rowIndex')).value = TextCellValue(department);
        sheet.cell(CellIndex.indexByString('B$rowIndex')).value = IntCellValue(stats['open'] ?? 0);
        sheet.cell(CellIndex.indexByString('C$rowIndex')).value = IntCellValue(stats['filled'] ?? 0);
        sheet.cell(CellIndex.indexByString('D$rowIndex')).value = IntCellValue(stats['cancelled'] ?? 0);
        sheet.cell(CellIndex.indexByString('E$rowIndex')).value = IntCellValue(stats['total'] ?? 0);
        sheet.cell(CellIndex.indexByString('F$rowIndex')).value = IntCellValue(stats['assigned_count'] ?? 0);
        rowIndex++;
      });

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(excel.encode()!);

      return filePath;
    } catch (e) {
      print('Error exporting shift summary to Excel: $e');
      return null;
    }
  }
}
