import 'package:flutter/material.dart';
import '../../services/shift_service.dart';
import '../../utils/datetime_utils.dart';
import '../../widgets/date_time_picker.dart';

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
        const SnackBar(content: Text("✅ משמרת נוצרה בהצלחה!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("יצירת משמרת חדשה")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📅 בחר תאריך", style: TextStyle(fontWeight: FontWeight.bold)),
            DatePickerWidget(
              initialDate: _selectedDate,
              onDateSelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 10),

            const Text("🏢 בחר מחלקה", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedDepartment = newValue!;
                });
              },
              items: departments.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),

            const Text("👥 מספר מקסימלי של עובדים", style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _maxWorkers.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: _maxWorkers.toString(),
              onChanged: (double value) {
                setState(() {
                  _maxWorkers = value.toInt();
                });
              },
            ),
            const SizedBox(height: 10),

            const Text("⏰ זמן התחלה", style: TextStyle(fontWeight: FontWeight.bold)),
            TimePickerWidget(
              initialTime: _startTime,
              onTimeSelected: (time) => setState(() => _startTime = time),
            ),
            const SizedBox(height: 10),

            const Text("⏰ זמן סיום", style: TextStyle(fontWeight: FontWeight.bold)),
            TimePickerWidget(
              initialTime: _endTime,
              onTimeSelected: (time) => setState(() => _endTime = time),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _createShift,
                child: const Text("✅ צור משמרת"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
