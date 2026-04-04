import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/config/departments.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

class CreateShiftScreen extends StatefulWidget {
  final DateTime? initialDate;

  const CreateShiftScreen({super.key, this.initialDate});

  @override
  State<CreateShiftScreen> createState() => _CreateShiftScreenState();
}

class _CreateShiftScreenState extends State<CreateShiftScreen> {
  late AppLocalizations _l10n;
  final ShiftService _shiftService = ShiftService();

  DateTime _selectedDate = DateTime.now();
  String _selectedDepartment = "פארק חבלים";
  int _maxWorkers = 3;
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);

  bool _isCreating = false;

  // Draft / recurring
  bool _recurringEnabled = false;
  int _repeatWeeks = 1;

  static const _kDraftDate = 'shift_draft_date';
  static const _kDraftDept = 'shift_draft_dept';
  static const _kDraftMax  = 'shift_draft_max';
  static const _kDraftStartH = 'shift_draft_startH';
  static const _kDraftStartM = 'shift_draft_startM';
  static const _kDraftEndH   = 'shift_draft_endH';
  static const _kDraftEndM   = 'shift_draft_endM';

  final List<Map<String, dynamic>> departments = [
    {
      'name': 'פארק חבלים',
      'icon': PhosphorIconsRegular.tree,
      'color': const Color(0xFF43A047)
    },
    {
      'name': 'פיינטבול',
      'icon': PhosphorIconsRegular.gameController,
      'color': const Color(0xFFE53935)
    },
    {
      'name': 'קרטינג',
      'icon': PhosphorIconsRegular.car,
      'color': const Color(0xFFFF9800)
    },
    {'name': 'פארק מים', 'icon': PhosphorIconsRegular.waves, 'color': const Color(0xFF1E88E5)},
    {
      'name': 'גמבורי',
      'icon': PhosphorIconsRegular.baby,
      'color': const Color(0xFF8E24AA)
    },
  ];

  Color get _selectedColor {
    final dept = departments.firstWhere(
      (d) => d['name'] == _selectedDepartment,
      orElse: () => departments.first,
    );
    return dept['color'] as Color;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    // Don't override a pre-set initialDate
    if (widget.initialDate != null) return;
    final prefs = await SharedPreferences.getInstance();
    final dateMs = prefs.getInt(_kDraftDate);
    if (dateMs == null) return; // no draft
    setState(() {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(dateMs);
      _selectedDepartment = prefs.getString(_kDraftDept) ?? _selectedDepartment;
      _maxWorkers        = prefs.getInt(_kDraftMax)       ?? _maxWorkers;
      _startTime = TimeOfDay(
        hour:   prefs.getInt(_kDraftStartH) ?? _startTime.hour,
        minute: prefs.getInt(_kDraftStartM) ?? _startTime.minute,
      );
      _endTime = TimeOfDay(
        hour:   prefs.getInt(_kDraftEndH) ?? _endTime.hour,
        minute: prefs.getInt(_kDraftEndM) ?? _endTime.minute,
      );
    });
    // Notify the user that a draft was restored
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(PhosphorIconsRegular.arrowCounterClockwise, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(_l10n.draftRestoredSnackbar, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            backgroundColor: const Color(0xFF6366F1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: _l10n.clearButton,
              textColor: Colors.white,
              onPressed: () async {
                await _clearDraft();
                setState(() {
                  _selectedDate = DateTime.now();
                  _selectedDepartment = departments.first['name'] as String;
                  _maxWorkers = 3;
                  _startTime = const TimeOfDay(hour: 9, minute: 0);
                  _endTime = const TimeOfDay(hour: 17, minute: 0);
                });
              },
            ),
          ),
        );
      });
    }
  }

  Future<void> _saveDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDraftDate, _selectedDate.millisecondsSinceEpoch);
    await prefs.setString(_kDraftDept, _selectedDepartment);
    await prefs.setInt(_kDraftMax, _maxWorkers);
    await prefs.setInt(_kDraftStartH, _startTime.hour);
    await prefs.setInt(_kDraftStartM, _startTime.minute);
    await prefs.setInt(_kDraftEndH, _endTime.hour);
    await prefs.setInt(_kDraftEndM, _endTime.minute);
  }

  Future<void> _clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kDraftDate);
    await prefs.remove(_kDraftDept);
    await prefs.remove(_kDraftMax);
    await prefs.remove(_kDraftStartH);
    await prefs.remove(_kDraftStartM);
    await prefs.remove(_kDraftEndH);
    await prefs.remove(_kDraftEndM);
  }

  Future<void> _createShift() async {
    if (_isCreating) return;
    setState(() => _isCreating = true);

    try {
      final weeks = _recurringEnabled ? _repeatWeeks : 1;
      for (int i = 0; i < weeks; i++) {
        final date = _selectedDate.add(Duration(days: 7 * i));
        await _shiftService.createShift(
          date: DateTimeUtils.formatDate(date),
          startTime: DateTimeUtils.formatTime(_startTime),
          endTime: DateTimeUtils.formatTime(_endTime),
          department: _selectedDepartment,
          maxWorkers: _maxWorkers,
        );
      }

      await _clearDraft();

      if (mounted) {
        Navigator.pop(context);
        final label = _recurringEnabled && _repeatWeeks > 1
            ? _l10n.shiftsCreatedSuccess(_repeatWeeks)
            : _l10n.shiftCreatedSuccess;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(PhosphorIconsFill.checkCircle, color: Colors.white),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_l10n.createShiftError(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    if (date != null) {
      setState(() => _selectedDate = date);
      _saveDraft();
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
      _saveDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        body: Column(
          children: [
            const UserHeader(),
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
                          _buildRecurringSection(),
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
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_selectedColor, _selectedColor.withValues(alpha: 0.8)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _selectedColor.withValues(alpha: 0.3),
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
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(PhosphorIconsRegular.plusCircle,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.createNewShiftTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _l10n.createShiftSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
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
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
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
      title: _l10n.dateLabel,
      child: InkWell(
        onTap: _selectDate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _selectedColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.calendarBlank,
                    color: _selectedColor, size: 22),
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
                Text(
                  DateTimeUtils.getLocalizedWeekdayName(_selectedDate.weekday, Localizations.localeOf(context).languageCode),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                Icon(PhosphorIconsRegular.calendarPlus, color: _selectedColor, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentSection() {
    return _buildSectionCard(
      title: _l10n.departmentLabel,
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
              onTap: () {
                setState(() => _selectedDepartment = dept['name'] as String);
                _saveDraft();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dept['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      getLocalizedDepartmentName(dept['name'] as String, _l10n),
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
    return _buildSectionCard(
      title: _l10n.hoursLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(child: _buildTimeButton(_l10n.startTimeLabel, _startTime, true)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  Icon(PhosphorIconsRegular.arrowRight, color: Colors.grey.shade500, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeButton(_l10n.endTimeLabel, _endTime, false)),
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
          color: _selectedColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _selectedColor.withValues(alpha: 0.2)),
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
                Icon(PhosphorIconsRegular.clock, color: _selectedColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  time.format(context),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _selectedColor,
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
    return _buildSectionCard(
      title: _l10n.maxWorkersLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            _buildWorkerCountButton(PhosphorIconsRegular.plus, () {
              setState(() => _maxWorkers++);
              _saveDraft();
            }),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsRegular.users, color: _selectedColor, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      '$_maxWorkers',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _selectedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildWorkerCountButton(PhosphorIconsRegular.minus, () {
              if (_maxWorkers > 1) {
                setState(() => _maxWorkers--);
                _saveDraft();
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerCountButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: _selectedColor.withValues(alpha: 0.1),
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

  Widget _buildRecurringSection() {
    final previewDates = List.generate(
      _recurringEnabled ? _repeatWeeks : 0,
      (i) => _selectedDate.add(Duration(days: 7 * i)),
    );

    return _buildSectionCard(
      title: _l10n.weeklyRecurrenceLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Switch(
                  value: _recurringEnabled,
                  activeThumbColor: _selectedColor,
                  onChanged: (v) => setState(() => _recurringEnabled = v),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _recurringEnabled
                        ? _l10n.shiftRepeatsWeekly
                        : _l10n.createRecurringShift,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _recurringEnabled
                            ? _selectedColor
                            : Colors.grey.shade800),
                  ),
                ),
              ],
            ),
            if (_recurringEnabled) ...[
              const SizedBox(height: 12),
              // Week counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(_l10n.numberOfWeeksLabel,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.minusCircle),
                      color: _selectedColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _repeatWeeks > 1
                          ? () => setState(() => _repeatWeeks--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('$_repeatWeeks',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _selectedColor)),
                    ),
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.plusCircle),
                      color: _selectedColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _repeatWeeks < 12
                          ? () => setState(() => _repeatWeeks++)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Date preview list
              Text(
                _l10n.shiftsToBeCreatedLabel,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ...previewDates.asMap().entries.map((entry) {
                final i = entry.key;
                final date = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _selectedColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateTimeUtils.getLocalizedWeekdayName(date.weekday, Localizations.localeOf(context).languageCode),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedColor),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
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
            color: _selectedColor.withValues(alpha: 0.4),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsFill.checkCircle, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    _l10n.createShiftButton,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          Icon(PhosphorIconsRegular.arrowRight, color: Colors.grey.shade600, size: 18),
          const SizedBox(width: 6),
          Text(
            _l10n.cancelButton,
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
