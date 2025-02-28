import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/services/shift_service.dart';
import 'package:park_janana/utils/datetime_utils.dart';
import 'package:park_janana/widgets/date_time_picker.dart';

class CreateShiftScreen extends StatefulWidget {
  const CreateShiftScreen({super.key});

  @override
  State<CreateShiftScreen> createState() => _CreateShiftScreenState();
}

class _CreateShiftScreenState extends State<CreateShiftScreen> {
  final ShiftService _shiftService = ShiftService();

  DateTime _selectedDate = DateTime.now();
  String _selectedDepartment = "פארק חבלים";
  int _maxWorkers = 1;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now();

  final List<String> departments = [
    "פארק חבלים",
    "פיינטבול",
    "קרטינג",
    "פארק מים",
    "גמבורי"
  ];

  void _createShift() async {
    await _shiftService.createShift(
      date: DateTimeUtils.formatDate(_selectedDate),
      startTime: DateTimeUtils.formatTime(_startTime),
      endTime: DateTimeUtils.formatTime(_endTime),
      department: _selectedDepartment,
      maxWorkers: _maxWorkers,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ משמרת נוצרה בהצלחה!", style: AppTheme.bodyText),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ✅ Park Logo & Header
            const UserHeader(),

            const SizedBox(height: 20),

            // ✅ Page Title
            Text("יצירת משמרת חדשה", style: AppTheme.screenTitle),

            const SizedBox(height: 20),

            // 📅 **Select Date**
            Align(
              alignment: Alignment.centerRight,
              child: Text("בחר תאריך", style: AppTheme.sectionTitle),
            ),
            DatePickerWidget(
              initialDate: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),

            const SizedBox(height: 20),

            // 🏢 **Select Department**
            Align(
              alignment: Alignment.centerRight,
              child: Text("בחר מחלקה", style: AppTheme.sectionTitle),
            ),
            DropdownButtonFormField<String>(
              value: _selectedDepartment,
              decoration: AppTheme.inputDecoration(hintText: "בחר מחלקה"),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDepartment = newValue!;
                });
              },
              items: departments.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: AppTheme.bodyText),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 👥 **Select Maximum Workers**
            Align(
              alignment: Alignment.centerRight,
              child: Text("מספר מקסימלי של עובדים", style: AppTheme.sectionTitle),
            ),
            Slider(
              value: _maxWorkers.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: _maxWorkers.toString(),
              activeColor: AppColors.accent,
              onChanged: (double value) {
                setState(() {
                  _maxWorkers = value.toInt();
                });
              },
            ),

            const SizedBox(height: 20),

            // ⏰ **Select Start Time**
            Align(
              alignment: Alignment.centerRight,
              child: Text("זמן התחלה", style: AppTheme.sectionTitle),
            ),
            TimePickerWidget(
              initialTime: _startTime,
              onTimeSelected: (time) => setState(() => _startTime = time),
            ),

            const SizedBox(height: 20),

            // ⏰ **Select End Time**
            Align(
              alignment: Alignment.centerRight,
              child: Text("זמן סיום", style: AppTheme.sectionTitle),
            ),
            TimePickerWidget(
              initialTime: _endTime,
              onTimeSelected: (time) => setState(() => _endTime = time),
            ),

            const SizedBox(height: 30),

            // ✅ **Create Shift Button**
            ElevatedButton(
              style: AppTheme.primaryButtonStyle,
              onPressed: _createShift,
              child: Text("צור משמרת", style: AppTheme.buttonTextStyle),
            ),

            const SizedBox(height: 15),

            // ❌ **Cancel Button**
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("חזור", style: AppTheme.linkTextStyle),
            ),
          ],
        ),
      ),
    );
  }
}
