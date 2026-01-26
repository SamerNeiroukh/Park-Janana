import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:park_janana/services/report_service.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/widgets/attendance/month_selector.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/config/departments.dart';
import 'package:flutter/services.dart';

class ShiftSummaryReport extends StatefulWidget {
  const ShiftSummaryReport({super.key});

  @override
  State<ShiftSummaryReport> createState() => _ShiftSummaryReportState();
}

class _ShiftSummaryReportState extends State<ShiftSummaryReport> {
  late DateTime selectedMonth;
  bool isLoading = true;
  Map<String, Map<String, int>> shiftSummary = {};
  String? selectedDepartment;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now();
    _loadShiftSummary();
  }

  Future<void> _loadShiftSummary() async {
    setState(() => isLoading = true);
    
    final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    
    final summary = await ReportService.getShiftSummaryByDepartment(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
    
    setState(() {
      shiftSummary = summary;
      isLoading = false;
    });
  }

  void _onMonthChanged(DateTime newMonth) {
    setState(() => selectedMonth = newMonth);
    _loadShiftSummary();
  }

  Future<void> _exportToExcel() async {
    if (shiftSummary.isEmpty) return;
    
    final formattedMonth = DateFormat('yyyy-MM', 'he').format(selectedMonth);
    final fileName = 'shift_summary_$formattedMonth.xlsx';
    
    final filePath = await ReportService.exportShiftSummaryToExcel(
      shiftSummary,
      fileName,
    );
    
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('הדוח נשמר בהצלחה: $filePath'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Copy file path to clipboard
      Clipboard.setData(ClipboardData(text: filePath));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('שגיאה בשמירת הדוח'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<String, Map<String, int>> get filteredSummary {
    if (selectedDepartment == null || selectedDepartment!.isEmpty) {
      return shiftSummary;
    }
    return Map.fromEntries(
      shiftSummary.entries.where((entry) => entry.key == selectedDepartment),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedMonth = DateFormat.yMMMM('he').format(selectedMonth);
    final displayData = filteredSummary;
    
    // Calculate totals
    int totalShifts = 0;
    int totalOpen = 0;
    int totalFilled = 0;
    int totalCancelled = 0;
    int totalAssigned = 0;
    
    displayData.forEach((_, stats) {
      totalShifts += stats['total'] ?? 0;
      totalOpen += stats['open'] ?? 0;
      totalFilled += stats['filled'] ?? 0;
      totalCancelled += stats['cancelled'] ?? 0;
      totalAssigned += stats['assigned_count'] ?? 0;
    });

    return Scaffold(
      appBar: const UserHeader(),
      body: SafeArea(
        child: Column(
          children: [
            MonthSelector(
              selectedMonth: selectedMonth,
              onMonthChanged: _onMonthChanged,
            ),
            
            // Department Filter
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'דוח סיכום משמרות - $formattedMonth',
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'סנן לפי מחלקה',
                        border: OutlineInputBorder(),
                      ),
                      value: selectedDepartment,
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('כל המחלקות'),
                        ),
                        ...allDepartments.map((dept) => DropdownMenuItem<String>(
                          value: dept,
                          child: Text(dept),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() => selectedDepartment = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Summary Totals
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('סה״כ', totalShifts, Colors.blue),
                    _buildSummaryItem('פתוחות', totalOpen, Colors.orange),
                    _buildSummaryItem('מלאות', totalFilled, Colors.green),
                    _buildSummaryItem('מבוטלות', totalCancelled, Colors.red),
                  ],
                ),
              ),
            ),
            
            if (isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (displayData.isEmpty)
              const Expanded(child: Center(child: Text('אין נתוני משמרות זמינים לחודש זה')))
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          itemCount: displayData.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final department = displayData.keys.elementAt(index);
                            final stats = displayData[department]!;
                            
                            return Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      department,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStatColumn('פתוחות', stats['open'] ?? 0, Colors.orange),
                                        _buildStatColumn('מלאות', stats['filled'] ?? 0, Colors.green),
                                        _buildStatColumn('מבוטלות', stats['cancelled'] ?? 0, Colors.red),
                                        _buildStatColumn('סה״כ', stats['total'] ?? 0, Colors.blue),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'עובדים מוקצים: ${stats['assigned_count'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _exportToExcel,
                          icon: const Icon(Icons.file_download),
                          label: const Text('יצוא לאקסל'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}