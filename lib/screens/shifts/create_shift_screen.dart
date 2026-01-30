import 'package:flutter/material.dart';
import 'package:park_janana/constants/app_dimensions.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/services/shift_service.dart';
import 'package:park_janana/utils/datetime_utils.dart';
import 'package:park_janana/widgets/date_time_picker.dart';

class CreateShiftScreen extends StatefulWidget {
  final DateTime? initialDate; // ✅ Allows passing a preselected date

  const CreateShiftScreen({super.key, this.initialDate});

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

  bool _isCreating = false;

  final List<String> departments = [
    "פארק חבלים",
    "פיינטבול",
    "קרטינג",
    "פארק מים",
    "גמבורי"
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now(); // ✅ Use initial date if provided
  }

  void _createShift() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("שגיאה ביצירת משמרת: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: AppDimensions.paddingAllL,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const UserHeader(),
            const SizedBox(height: AppDimensions.spacingXL),
            Text("יצירת משמרת חדשה", style: AppTheme.screenTitle),
            const SizedBox(height: AppDimensions.spacingXL),

            Align(
              alignment: Alignment.centerRight,
              child: Text("בחר תאריך", style: AppTheme.sectionTitle),
            ),
            DatePickerWidget(
              initialDate: _selectedDate,
              onDateSelected: (date) => setState(() {
                _selectedDate = date;
              }),
            ),
            const SizedBox(height: AppDimensions.spacingXL),

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
            const SizedBox(height: AppDimensions.spacingXL),

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
            const SizedBox(height: AppDimensions.spacingXL),

            Align(
              alignment: Alignment.centerRight,
              child: Text("זמן התחלה", style: AppTheme.sectionTitle),
            ),
            TimePickerWidget(
              initialTime: _startTime,
              onTimeSelected: (time) => setState(() {
                _startTime = time;
              }),
            ),
            const SizedBox(height: AppDimensions.spacingXL),

            Align(
              alignment: Alignment.centerRight,
              child: Text("זמן סיום", style: AppTheme.sectionTitle),
            ),
            TimePickerWidget(
              initialTime: _endTime,
              onTimeSelected: (time) => setState(() {
                _endTime = time;
              }),
            ),
            const SizedBox(height: AppDimensions.spacingXXXL),

            ElevatedButton(
              style: AppTheme.primaryButtonStyle,
              onPressed: _isCreating ? null : _createShift,
              child: _isCreating
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("צור משמרת", style: AppTheme.buttonTextStyle),
            ),
            const SizedBox(height: AppDimensions.spacingL),

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
