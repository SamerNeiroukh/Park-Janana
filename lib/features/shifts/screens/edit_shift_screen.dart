import 'package:flutter/material.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/services/notification_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:intl/intl.dart' hide TextDirection;

class EditShiftScreen extends StatefulWidget {
  final ShiftModel shift;
  final ShiftService shiftService;

  const EditShiftScreen({
    super.key,
    required this.shift,
    required this.shiftService,
  });

  @override
  State<EditShiftScreen> createState() => _EditShiftScreenState();
}

class _EditShiftScreenState extends State<EditShiftScreen> {
  // Draft values (changes are not saved until user presses save)
  late DateTime _selectedDate;
  late String _selectedDepartment;
  late int _maxWorkers;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late String _status;

  // Original values for comparison
  late DateTime _originalDate;
  late String _originalDepartment;
  late int _originalMaxWorkers;
  late TimeOfDay _originalStartTime;
  late TimeOfDay _originalEndTime;
  late String _originalStatus;

  bool _isSaving = false;
  bool _hasChanges = false;

  final List<Map<String, dynamic>> departments = [
    {'name': 'פארק חבלים', 'icon': Icons.park, 'color': const Color(0xFF43A047)},
    {'name': 'פיינטבול', 'icon': Icons.sports_esports, 'color': const Color(0xFFE53935)},
    {'name': 'קרטינג', 'icon': Icons.directions_car, 'color': const Color(0xFFFF9800)},
    {'name': 'פארק מים', 'icon': Icons.pool, 'color': const Color(0xFF1E88E5)},
    {'name': 'גמבורי', 'icon': Icons.child_care, 'color': const Color(0xFF8E24AA)},
  ];

  final List<Map<String, dynamic>> statusOptions = [
    {'value': 'active', 'label': 'פעיל', 'color': AppColors.success, 'icon': Icons.check_circle},
    {'value': 'cancelled', 'label': 'בוטל', 'color': Colors.red, 'icon': Icons.cancel},
    {'value': 'completed', 'label': 'הושלם', 'color': Colors.blue, 'icon': Icons.done_all},
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
    _initializeValues();
  }

  void _initializeValues() {
    // Parse the shift values
    _originalDate = DateFormat('dd/MM/yyyy').parse(widget.shift.date);
    _originalDepartment = widget.shift.department;
    _originalMaxWorkers = widget.shift.maxWorkers;
    _originalStatus = widget.shift.status;

    // Parse start time
    final startParts = widget.shift.startTime.split(':');
    _originalStartTime = TimeOfDay(
      hour: int.parse(startParts[0]),
      minute: int.parse(startParts[1]),
    );

    // Parse end time
    final endParts = widget.shift.endTime.split(':');
    _originalEndTime = TimeOfDay(
      hour: int.parse(endParts[0]),
      minute: int.parse(endParts[1]),
    );

    // Set draft values to original
    _selectedDate = _originalDate;
    _selectedDepartment = _originalDepartment;
    _maxWorkers = _originalMaxWorkers;
    _startTime = _originalStartTime;
    _endTime = _originalEndTime;
    _status = _originalStatus;
  }

  void _checkForChanges() {
    final hasChanges = _selectedDate != _originalDate ||
        _selectedDepartment != _originalDepartment ||
        _maxWorkers != _originalMaxWorkers ||
        _startTime != _originalStartTime ||
        _endTime != _originalEndTime ||
        _status != _originalStatus;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  List<String> _getChangeSummary() {
    final List<String> changes = [];

    if (_selectedDate != _originalDate) {
      changes.add('תאריך: ${DateFormat('dd/MM/yyyy').format(_originalDate)} → ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
    }
    if (_selectedDepartment != _originalDepartment) {
      changes.add('מחלקה: $_originalDepartment → $_selectedDepartment');
    }
    if (_startTime != _originalStartTime || _endTime != _originalEndTime) {
      changes.add('שעות: ${_formatTime(_originalStartTime)}-${_formatTime(_originalEndTime)} → ${_formatTime(_startTime)}-${_formatTime(_endTime)}');
    }
    if (_maxWorkers != _originalMaxWorkers) {
      changes.add('מקסימום עובדים: $_originalMaxWorkers → $_maxWorkers');
    }
    if (_status != _originalStatus) {
      final oldLabel = statusOptions.firstWhere((s) => s['value'] == _originalStatus)['label'];
      final newLabel = statusOptions.firstWhere((s) => s['value'] == _status)['label'];
      changes.add('סטטוס: $oldLabel → $newLabel');
    }

    return changes;
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveChanges() async {
    if (_isSaving || !_hasChanges) return;

    // Show confirmation dialog with changes summary
    final changes = _getChangeSummary();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.save, color: _selectedColor),
              ),
              const SizedBox(width: 12),
              const Text('שמירת שינויים'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'השינויים הבאים יישמרו:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...changes.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  textDirection: TextDirection.rtl,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: _selectedColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        change,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    const Icon(Icons.notifications_active,
                        size: 20, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'כל העובדים המשובצים והממתינים יקבלו התראה על השינויים',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('ביטול', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('שמור שינויים', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      final affectedWorkers = await widget.shiftService.updateShiftDetails(
        shiftId: widget.shift.id,
        date: _selectedDate != _originalDate
            ? DateFormat('dd/MM/yyyy').format(_selectedDate)
            : null,
        startTime: _startTime != _originalStartTime
            ? _formatTime(_startTime)
            : null,
        endTime: _endTime != _originalEndTime
            ? _formatTime(_endTime)
            : null,
        department: _selectedDepartment != _originalDepartment
            ? _selectedDepartment
            : null,
        maxWorkers: _maxWorkers != _originalMaxWorkers ? _maxWorkers : null,
        status: _status != _originalStatus ? _status : null,
      );

      // Send notifications to affected workers (non-blocking)
      if (affectedWorkers.isNotEmpty) {
        try {
          final changes = _getChangeSummary();
          await NotificationService().notifyShiftUpdate(
            shiftId: widget.shift.id,
            workerIds: affectedWorkers,
            shiftDate: DateFormat('dd/MM/yyyy').format(_selectedDate),
            department: _selectedDepartment,
            changes: changes,
          );
        } catch (e) {
          debugPrint('Notification error (non-blocking): $e');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'המשמרת עודכנה בהצלחה!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.right,
                  ),
                ),
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
            content: Text('שגיאה בעדכון המשמרת: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
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
    if (date != null) {
      setState(() => _selectedDate = date);
      _checkForChanges();
    }
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
      _checkForChanges();
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warningOrange),
              SizedBox(width: 12),
              Text('שינויים לא שמורים'),
            ],
          ),
          content: const Text('יש לך שינויים שלא נשמרו. האם אתה בטוח שברצונך לצאת?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('המשך לערוך', style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('צא ללא שמירה', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Directionality(
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
                            const SizedBox(height: 20),
                            _buildStatusSection(),
                            const SizedBox(height: 32),
                            _buildSaveButton(),
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
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
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
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.edit, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'עריכת משמרת',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasChanges ? 'יש שינויים לא שמורים' : 'עדכן את פרטי המשמרת',
                  style: TextStyle(
                    fontSize: 14,
                    color: _hasChanges
                        ? Colors.yellow.shade200
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          if (_hasChanges)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: _selectedColor, size: 20),
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
    final isChanged = _selectedDate != _originalDate;

    return _buildSectionCard(
      title: 'תאריך',
      child: InkWell(
        onTap: _selectDate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isChanged
                  ? AppColors.warningOrange.withOpacity(0.1)
                  : _selectedColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isChanged
                    ? AppColors.warningOrange.withOpacity(0.5)
                    : _selectedColor.withOpacity(0.2),
                width: isChanged ? 2 : 1,
              ),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: isChanged ? AppColors.warningOrange : _selectedColor,
                    size: 22),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isChanged ? AppColors.warningOrange : _selectedColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  DateTimeUtils.getHebrewWeekdayName(_selectedDate.weekday),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                if (isChanged)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warningOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'שונה',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.edit_calendar,
                    color: isChanged ? AppColors.warningOrange : _selectedColor,
                    size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentSection() {
    final isChanged = _selectedDepartment != _originalDepartment;

    return _buildSectionCard(
      title: isChanged ? 'מחלקה (שונה)' : 'מחלקה',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          textDirection: TextDirection.rtl,
          children: departments.map((dept) {
            final isSelected = dept['name'] == _selectedDepartment;
            final color = dept['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() => _selectedDepartment = dept['name']);
                _checkForChanges();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      dept['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dept['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
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
    final isChanged = _startTime != _originalStartTime || _endTime != _originalEndTime;

    return _buildSectionCard(
      title: isChanged ? 'שעות (שונה)' : 'שעות',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(child: _buildTimeButton('התחלה', _startTime, true)),
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
            Expanded(child: _buildTimeButton('סיום', _endTime, false)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(String label, TimeOfDay time, bool isStart) {
    final isChanged = isStart
        ? time != _originalStartTime
        : time != _originalEndTime;

    return InkWell(
      onTap: () => _selectTime(isStart),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isChanged
              ? AppColors.warningOrange.withOpacity(0.1)
              : _selectedColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChanged
                ? AppColors.warningOrange.withOpacity(0.5)
                : _selectedColor.withOpacity(0.2),
            width: isChanged ? 2 : 1,
          ),
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
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.access_time,
                    color: isChanged ? AppColors.warningOrange : _selectedColor,
                    size: 18),
                const SizedBox(width: 6),
                Text(
                  _formatTime(time),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isChanged ? AppColors.warningOrange : _selectedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersSection() {
    final isChanged = _maxWorkers != _originalMaxWorkers;

    return _buildSectionCard(
      title: isChanged ? 'מספר עובדים מקסימלי (שונה)' : 'מספר עובדים מקסימלי',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _buildWorkerCountButton(Icons.add, () {
                  setState(() => _maxWorkers++);
                  _checkForChanges();
                }),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isChanged
                          ? AppColors.warningOrange.withOpacity(0.1)
                          : _selectedColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: isChanged
                          ? Border.all(
                              color: AppColors.warningOrange.withOpacity(0.5),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(Icons.people,
                            color: isChanged ? AppColors.warningOrange : _selectedColor,
                            size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '$_maxWorkers',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isChanged ? AppColors.warningOrange : _selectedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildWorkerCountButton(Icons.remove, () {
                  if (_maxWorkers > 1) {
                    setState(() => _maxWorkers--);
                    _checkForChanges();
                  }
                }),
              ],
            ),
            if (widget.shift.assignedWorkers.length > _maxWorkers)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(Icons.warning, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'יש כרגע ${widget.shift.assignedWorkers.length} עובדים משובצים, יותר מהמקסימום החדש',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.red,
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

  Widget _buildStatusSection() {
    final isChanged = _status != _originalStatus;

    return _buildSectionCard(
      title: isChanged ? 'סטטוס (שונה)' : 'סטטוס',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
          textDirection: TextDirection.rtl,
          children: statusOptions.map((status) {
            final isSelected = status['value'] == _status;
            final color = status['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() => _status = status['value']);
                _checkForChanges();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(
                      status['icon'] as IconData,
                      size: 20,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status['label'] as String,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
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

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: _hasChanges
            ? [
                BoxShadow(
                  color: _selectedColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: _hasChanges && !_isSaving ? _saveChanges : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasChanges ? _selectedColor : Colors.grey.shade300,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    _hasChanges ? Icons.save : Icons.check,
                    size: 22,
                    color: _hasChanges ? Colors.white : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasChanges ? 'שמור שינויים' : 'אין שינויים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _hasChanges ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCancelButton() {
    return TextButton(
      onPressed: () async {
        if (await _onWillPop()) {
          if (mounted) Navigator.pop(context);
        }
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          Icon(Icons.arrow_forward, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 6),
          Text(
            'ביטול',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
