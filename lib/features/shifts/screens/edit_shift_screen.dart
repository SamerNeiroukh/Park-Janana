import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/config/departments.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/features/shifts/models/shift_model.dart';
import 'package:park_janana/features/shifts/services/shift_service.dart';
import 'package:park_janana/core/utils/datetime_utils.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/widgets/app_dialog.dart';

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
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  final List<Map<String, dynamic>> departments = [
    {'name': 'פארק חבלים', 'icon': PhosphorIconsRegular.tree, 'color': const Color(0xFF43A047)},
    {'name': 'פיינטבול', 'icon': PhosphorIconsRegular.gameController, 'color': const Color(0xFFE53935)},
    {'name': 'קרטינג', 'icon': PhosphorIconsRegular.car, 'color': const Color(0xFFFF9800)},
    {'name': 'פארק מים', 'icon': PhosphorIconsRegular.waves, 'color': const Color(0xFF1E88E5)},
    {'name': 'גמבורי', 'icon': PhosphorIconsRegular.baby, 'color': const Color(0xFF8E24AA)},
  ];

  final List<Map<String, dynamic>> statusOptions = [
    {'value': 'active', 'color': AppColors.success, 'icon': PhosphorIconsFill.checkCircle},
    {'value': 'cancelled', 'color': Colors.red, 'icon': PhosphorIconsRegular.xCircle},
    {'value': 'completed', 'color': Colors.blue, 'icon': PhosphorIconsRegular.checks},
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

  String _statusLabel(String value) {
    switch (value) {
      case 'active': return _l10n.shiftStatusActive;
      case 'cancelled': return _l10n.shiftStatusCancelledMasc;
      case 'completed': return _l10n.shiftStatusCompleted;
      default: return value;
    }
  }

  List<String> _getChangeSummary() {
    final List<String> changes = [];

    if (_selectedDate != _originalDate) {
      changes.add('${_l10n.dateLabel}: ${DateFormat('dd/MM/yyyy').format(_originalDate)} → ${DateFormat('dd/MM/yyyy').format(_selectedDate)}');
    }
    if (_selectedDepartment != _originalDepartment) {
      changes.add('${_l10n.departmentLabel}: $_originalDepartment → $_selectedDepartment');
    }
    if (_startTime != _originalStartTime || _endTime != _originalEndTime) {
      changes.add('${_l10n.hoursLabel}: ${_formatTime(_originalStartTime)}-${_formatTime(_originalEndTime)} → ${_formatTime(_startTime)}-${_formatTime(_endTime)}');
    }
    if (_maxWorkers != _originalMaxWorkers) {
      changes.add('${_l10n.maxWorkersLabel}: $_originalMaxWorkers → $_maxWorkers');
    }
    if (_status != _originalStatus) {
      changes.add('${_l10n.statusLabel}: ${_statusLabel(_originalStatus)} → ${_statusLabel(_status)}');
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
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(PhosphorIconsRegular.floppyDisk, color: _selectedColor),
              ),
              const SizedBox(width: 12),
              Text(_l10n.saveChangesDialogTitle),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l10n.followingChangesSavedLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...changes.map((change) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(PhosphorIconsRegular.arrowRight, size: 16, color: _selectedColor),
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
                  color: AppColors.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.bellRinging,
                        size: 20, color: AppColors.warningOrange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _l10n.workersNotifiedOfChanges,
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
              child: Text(_l10n.cancelButton, style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(_l10n.saveChangesButton, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);

    try {
      await widget.shiftService.updateShiftDetails(
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

      // Notifications are sent automatically by the onShiftWritten Cloud Function.

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(PhosphorIconsFill.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _l10n.shiftUpdatedSuccess,
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
            content: Text(_l10n.updateShiftError(e.toString())),
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

    final result = await showAppDialog(
      context,
      title: _l10n.unsavedChangesTitle,
      message: _l10n.unsavedChangesMessage,
      confirmText: _l10n.exitWithoutSavingButton,
      cancelText: _l10n.continueEditingButton,
      icon: PhosphorIconsRegular.warning,
      iconGradient: const [Color(0xFFFF8C00), Color(0xFFE65100)],
      isDestructive: true,
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
      child: Scaffold(
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
            child: const Icon(PhosphorIconsRegular.pencilSimple, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.editShiftTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasChanges ? _l10n.unsavedChangesHeaderSubtitle : _l10n.updateShiftDetailsSubtitle,
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
              child: Icon(PhosphorIconsRegular.pencilSimple, color: _selectedColor, size: 20),
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
    final isChanged = _selectedDate != _originalDate;

    return _buildSectionCard(
      title: _l10n.dateLabel,
      child: InkWell(
        onTap: _selectDate,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isChanged
                  ? AppColors.warningOrange.withValues(alpha: 0.1)
                  : _selectedColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isChanged
                    ? AppColors.warningOrange.withValues(alpha: 0.5)
                    : _selectedColor.withValues(alpha: 0.2),
                width: isChanged ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.calendarBlank,
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
                  DateTimeUtils.getLocalizedWeekdayName(_selectedDate.weekday, Localizations.localeOf(context).languageCode),
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
                    child: Text(
                      _l10n.changedBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(PhosphorIconsRegular.calendarPlus,
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
      title: isChanged ? '${_l10n.departmentLabel} (${_l10n.changedBadge})' : _l10n.departmentLabel,
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
                setState(() => _selectedDepartment = dept['name']);
                _checkForChanges();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    final isChanged = _startTime != _originalStartTime || _endTime != _originalEndTime;

    return _buildSectionCard(
      title: isChanged ? '${_l10n.hoursLabel} (${_l10n.changedBadge})' : _l10n.hoursLabel,
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
              child: Icon(PhosphorIconsRegular.arrowRight, color: Colors.grey.shade500, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildTimeButton(_l10n.endTimeLabel, _endTime, false)),
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
              ? AppColors.warningOrange.withValues(alpha: 0.1)
              : _selectedColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChanged
                ? AppColors.warningOrange.withValues(alpha: 0.5)
                : _selectedColor.withValues(alpha: 0.2),
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
              children: [
                Icon(PhosphorIconsRegular.clock,
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
      title: isChanged ? '${_l10n.maxWorkersLabel} (${_l10n.changedBadge})' : _l10n.maxWorkersLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                _buildWorkerCountButton(PhosphorIconsRegular.plus, () {
                  setState(() => _maxWorkers++);
                  _checkForChanges();
                }),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isChanged
                          ? AppColors.warningOrange.withValues(alpha: 0.1)
                          : _selectedColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: isChanged
                          ? Border.all(
                              color: AppColors.warningOrange.withValues(alpha: 0.5),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.users,
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
                _buildWorkerCountButton(PhosphorIconsRegular.minus, () {
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
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.warning, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _l10n.tooManyWorkersWarning(widget.shift.assignedWorkers.length),
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

  Widget _buildStatusSection() {
    final isChanged = _status != _originalStatus;

    return _buildSectionCard(
      title: isChanged ? '${_l10n.statusLabel} (${_l10n.changedBadge})' : _l10n.statusLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.end,
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
                      status['icon'] as IconData,
                      size: 20,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusLabel(status['value'] as String),
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
                  color: _selectedColor.withValues(alpha: 0.4),
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
                children: [
                  Icon(
                    _hasChanges ? PhosphorIconsRegular.floppyDisk : PhosphorIconsRegular.check,
                    size: 22,
                    color: _hasChanges ? Colors.white : Colors.grey.shade500,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _hasChanges ? _l10n.saveChangesButton : _l10n.noChangesLabel,
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
