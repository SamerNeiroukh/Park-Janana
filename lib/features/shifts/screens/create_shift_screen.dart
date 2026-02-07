import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:intl/intl.dart' hide TextDirection;

class CreateShiftScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CreateShiftScreen({super.key, this.initialDate});

  @override
  State<CreateShiftScreen> createState() => _CreateShiftScreenState();
}

class _CreateShiftScreenState extends State<CreateShiftScreen> {
  final ShiftService _shiftService = ShiftService();

  DateTime _selectedDate = DateTime.now();
  String _selectedDepartment = "פארק חבלים";
  int _maxWorkers = 3;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _isCreating = false;

  final List<Map<String, dynamic>> departments = [
    {'name': 'פארק חבלים', 'icon': Icons.park, 'color': const Color(0xFF43A047)},
    {'name': 'פיינטבול', 'icon': Icons.sports_esports, 'color': const Color(0xFFE53935)},
    {'name': 'קרטינג', 'icon': Icons.directions_car, 'color': const Color(0xFFFF9800)},
    {'name': 'פארק מים', 'icon': Icons.pool, 'color': const Color(0xFF1E88E5)},
    {'name': 'גמבורי', 'icon': Icons.child_care, 'color': const Color(0xFF8E24AA)},
  ];

  Color get _selectedColor {
    final dept = departments.firstWhere(
      (d) => d['name'] == _selectedDepartment,
      orElse: () => departments.first,
    );
    return dept['color'] as Color;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  Future<void> _createShift() async {
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
            content: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'משמרת נוצרה בהצלחה!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.white),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה ביצירת משמרת: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _selectedColor),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _selectTime(bool isStart) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _selectedColor),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() {
        if (isStart) {
          _startTime = time;
        } else {
          _endTime = time;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildDateSection(),
                          const SizedBox(height: 20),
                          _buildDepartmentSection(),
                          const SizedBox(height: 20),
                          _buildTimeSection(),
                          const SizedBox(height: 20),
                          _buildWorkersSection(),
                          const SizedBox(height: 32),
                          _buildCreateButton(),
                          const SizedBox(height: 16),
                          _buildCancelButton(),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.add_circle_outline,
                color: Colors.white, size: 28),
          ),
          const Spacer(),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'יצירת משמרת חדשה',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'מלא את הפרטים ליצירת משמרת',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildDateSection() {
    return _buildSectionCard(
      title: 'תאריך',
      child: InkWell(
        onTap: _selectDate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _selectedColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit_calendar, color: _selectedColor, size: 22),
                const Spacer(),
                Text(
                  DateTimeUtils.getHebrewWeekdayName(_selectedDate.weekday),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _selectedColor,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.calendar_today_rounded,
                    color: _selectedColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentSection() {
    return _buildSectionCard(
      title: 'מחלקה',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          children: departments.map((dept) {
            final isSelected = dept['name'] == _selectedDepartment;
            final color = dept['color'] as Color;

            return GestureDetector(
              onTap: () => setState(() => _selectedDepartment = dept['name']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : color.withOpacity(0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dept['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      dept['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return _buildSectionCard(
      title: 'שעות',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(child: _buildTimeButton('סיום', _endTime, false)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey.shade500, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeButton('התחלה', _startTime, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(isStart),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _selectedColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _selectedColor.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedColor,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.access_time, color: _selectedColor, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersSection() {
    return _buildSectionCard(
      title: 'מספר עובדים מקסימלי',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                _buildWorkerCountButton(Icons.remove, () {
                  if (_maxWorkers > 1) setState(() => _maxWorkers--);
                }),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$_maxWorkers',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: _selectedColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people, color: _selectedColor, size: 28),
                      ],
                    ),
                  ),
                ),
                _buildWorkerCountButton(Icons.add, () {
                  if (_maxWorkers < 20) setState(() => _maxWorkers++);
                }),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: _selectedColor,
                inactiveTrackColor: _selectedColor.withOpacity(0.2),
                thumbColor: _selectedColor,
                overlayColor: _selectedColor.withOpacity(0.2),
                trackHeight: 6,
              ),
              child: Slider(
                value: _maxWorkers.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) => setState(() => _maxWorkers = value.toInt()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCountButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: _selectedColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: _selectedColor, size: 24),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isCreating ? null : _createShift,
        style: ElevatedButton.styleFrom(
          backgroundColor: _selectedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isCreating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'צור משמרת',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check_circle, size: 22),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'ביטול',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.arrow_forward, color: Colors.grey.shade600, size: 18),
        ],
      ),
    );
  }
}
