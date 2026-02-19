import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';
import '../theme/task_theme.dart';

class CreateTaskFlowScreen extends StatefulWidget {
  final List<UserModel>? initialSelectedUsers;

  const CreateTaskFlowScreen({super.key, this.initialSelectedUsers});

  @override
  State<CreateTaskFlowScreen> createState() => _CreateTaskFlowScreenState();
}

class _CreateTaskFlowScreenState extends State<CreateTaskFlowScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  // Step 1 — Basic Info
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _priority = 'medium';
  String _department = 'general';

  // Step 2 — Workers
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  final List<UserModel> _selectedWorkers = [];

  // Step 3 — Deadline
  DateTime? _dueDate;
  TimeOfDay? _dueTime;

  int _currentStep = 0;
  bool _isSubmitting = false;

  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final query = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .get();
    final users = query.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap({...data, 'uid': doc.id});
    }).toList();

    setState(() {
      _allUsers = users;
      _filteredUsers = users;
    });

    if (widget.initialSelectedUsers != null) {
      for (var user in widget.initialSelectedUsers!) {
        if (!_selectedWorkers.any((u) => u.uid == user.uid)) {
          _selectedWorkers.add(user);
        }
      }
    }
  }

  void _filterUsers(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers.where((u) =>
          u.fullName.toLowerCase().contains(lower) ||
          u.role.toLowerCase().contains(lower)).toList();
    });
  }

  void _goToStep(int step) {
    if (step < 0 || step > 3) return;

    // Validate before moving forward
    if (step > _currentStep) {
      if (_currentStep == 0 && !_validateStep1()) return;
      if (_currentStep == 1 && !_validateStep2()) return;
      if (_currentStep == 2 && !_validateStep3()) return;
    }

    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    setState(() => _currentStep = step);
  }

  bool _validateStep1() {
    if (_titleController.text.trim().isEmpty) {
      _showError('נא להזין כותרת למשימה');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedWorkers.isEmpty) {
      _showError('נא לבחור לפחות עובד אחד');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_dueDate == null || _dueTime == null) {
      _showError('נא לבחור תאריך ושעה');
      return false;
    }
    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: TaskTheme.overdue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: TaskTheme.background,
        body: Column(
          children: [
            const Directionality(
              textDirection: TextDirection.ltr,
              child: UserHeader(),
            ),
              _buildStepIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                    _buildStep4(),
                  ],
                ),
              ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['פרטים', 'עובדים', 'מועד', 'סיכום'];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: TaskTheme.softShadow,
      ),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = _currentStep == i;
          final isDone = _currentStep > i;

          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDone
                        ? TaskTheme.done
                        : isActive
                            ? TaskTheme.primary
                            : TaskTheme.background,
                    shape: BoxShape.circle,
                    boxShadow: (isActive || isDone)
                        ? [BoxShadow(
                            color: (isDone ? TaskTheme.done : TaskTheme.primary)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )]
                        : null,
                    border: (!isActive && !isDone)
                        ? Border.all(color: TaskTheme.border, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? Colors.white
                                  : TaskTheme.textTertiary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive
                        ? TaskTheme.primary
                        : isDone
                            ? TaskTheme.done
                            : TaskTheme.textTertiary,
                  ),
                ),
                if (i < 3)
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isDone ? TaskTheme.done : TaskTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Step 1: Basic Info ────────────────────────────────────

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('פרטי המשימה', style: TaskTheme.heading2),
            const SizedBox(height: 8),
            Text('מלא את הפרטים הבסיסיים של המשימה',
                style: TaskTheme.body),
            const SizedBox(height: 24),

            // Title
            _buildLabel('כותרת'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'שם המשימה',
              validator: (v) =>
                  v == null || v.isEmpty ? 'שדה חובה' : null,
            ),
            const SizedBox(height: 20),

            // Description
            _buildLabel('תיאור'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hint: 'תיאור מפורט (אופציונלי)',
              maxLines: 4,
            ),
            const SizedBox(height: 20),

            // Priority
            _buildLabel('עדיפות'),
            const SizedBox(height: 8),
            _buildPrioritySelector(),
            const SizedBox(height: 20),

            // Department
            _buildLabel('מחלקה'),
            const SizedBox(height: 8),
            _buildDepartmentSelector(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TaskTheme.label.copyWith(color: TaskTheme.textPrimary),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: TaskTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: TaskTheme.textTertiary),
        filled: true,
        fillColor: TaskTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          borderSide: const BorderSide(color: TaskTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          borderSide: const BorderSide(color: TaskTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          borderSide:
              const BorderSide(color: TaskTheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final items = [
      {'value': 'low', 'label': 'נמוכה', 'color': TaskTheme.lowPriority},
      {'value': 'medium', 'label': 'בינונית', 'color': TaskTheme.mediumPriority},
      {'value': 'high', 'label': 'גבוהה', 'color': TaskTheme.highPriority},
    ];

    return Row(
      children: items.map((item) {
        final val = item['value'] as String;
        final label = item['label'] as String;
        final color = item['color'] as Color;
        final isSelected = _priority == val;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = val),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : TaskTheme.surface,
                borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                border: Border.all(
                  color: isSelected ? color : TaskTheme.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(TaskTheme.priorityIcon(val), size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : TaskTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDepartmentSelector() {
    final depts = [
      'general', 'paintball', 'ropes', 'carting', 'water_park', 'jimbory',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: depts.map((d) {
        final isSelected = _department == d;
        return GestureDetector(
          onTap: () => setState(() => _department = d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? TaskTheme.primary.withOpacity(0.1)
                  : TaskTheme.surface,
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              border: Border.all(
                color: isSelected ? TaskTheme.primary : TaskTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              TaskTheme.departmentLabel(d),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? TaskTheme.primary : TaskTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Step 2: Workers ───────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('שיבוץ עובדים', style: TaskTheme.heading2),
              const SizedBox(height: 8),
              Text(
                'בחר ${_selectedWorkers.length} עובדים',
                style: TaskTheme.body,
              ),
              const SizedBox(height: 16),
              // Search
              Container(
                decoration: BoxDecoration(
                  color: TaskTheme.surface,
                  borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                  border: Border.all(color: TaskTheme.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterUsers,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'חיפוש לפי שם או תפקיד...',
                    hintStyle: const TextStyle(color: TaskTheme.textTertiary),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: TaskTheme.textTertiary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              // Selected chips
              if (_selectedWorkers.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedWorkers.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final w = _selectedWorkers[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TaskTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              w.fullName.split(' ').first,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: TaskTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() =>
                                  _selectedWorkers
                                      .removeWhere((u) => u.uid == w.uid)),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: TaskTheme.primary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _filteredUsers.length,
            itemBuilder: (context, i) {
              final user = _filteredUsers[i];
              final isSelected =
                  _selectedWorkers.any((u) => u.uid == user.uid);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedWorkers.removeWhere((u) => u.uid == user.uid);
                    } else {
                      _selectedWorkers.add(user);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? TaskTheme.primary.withOpacity(0.06)
                        : TaskTheme.surface,
                    borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                    border: Border.all(
                      color:
                          isSelected ? TaskTheme.primary : TaskTheme.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ProfileAvatar(
                        imageUrl: user.profilePicture,
                        radius: 20,
                        backgroundColor: TaskTheme.primary.withOpacity(0.1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.fullName, style: TaskTheme.label),
                            Text(user.role, style: TaskTheme.caption),
                          ],
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: isSelected
                            ? const Icon(Icons.check_circle_rounded,
                                key: ValueKey('checked'),
                                color: TaskTheme.primary,
                                size: 24)
                            : Icon(Icons.circle_outlined,
                                key: const ValueKey('unchecked'),
                                color: TaskTheme.textTertiary,
                                size: 24),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Deadline ──────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('מועד יעד', style: TaskTheme.heading2),
          const SizedBox(height: 8),
          Text('הגדר תאריך ושעת סיום למשימה', style: TaskTheme.body),
          const SizedBox(height: 32),

          // Date picker
          _buildPickerTile(
            icon: Icons.calendar_today_rounded,
            label: 'תאריך',
            value: _dueDate != null
                ? DateFormat('dd/MM/yyyy').format(_dueDate!)
                : 'בחר תאריך',
            onTap: _pickDate,
            isSet: _dueDate != null,
          ),
          const SizedBox(height: 16),

          // Time picker
          _buildPickerTile(
            icon: Icons.access_time_rounded,
            label: 'שעה',
            value: _dueTime != null
                ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                : 'בחר שעה',
            onTap: _pickTime,
            isSet: _dueTime != null,
          ),
        ],
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isSet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TaskTheme.surface,
          borderRadius: BorderRadius.circular(TaskTheme.radiusL),
          border: Border.all(
            color: isSet ? TaskTheme.primary : TaskTheme.border,
            width: isSet ? 1.5 : 1,
          ),
          boxShadow: TaskTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: TaskTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: TaskTheme.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TaskTheme.caption),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSet
                          ? TaskTheme.textPrimary
                          : TaskTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: TaskTheme.textTertiary, size: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('he', 'IL'),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  // ─── Step 4: Review ────────────────────────────────────────

  Widget _buildStep4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('סיכום ויצירה', style: TaskTheme.heading2),
          const SizedBox(height: 8),
          Text('בדוק את הפרטים לפני יצירת המשימה', style: TaskTheme.body),
          const SizedBox(height: 24),

          _buildReviewCard('כותרת', _titleController.text, Icons.title_rounded),
          if (_descriptionController.text.isNotEmpty)
            _buildReviewCard('תיאור', _descriptionController.text,
                Icons.description_outlined),
          _buildReviewCard('עדיפות', TaskTheme.priorityLabel(_priority),
              TaskTheme.priorityIcon(_priority)),
          _buildReviewCard('מחלקה', TaskTheme.departmentLabel(_department),
              Icons.business_rounded),
          _buildReviewCard(
            'עובדים',
            _selectedWorkers.map((w) => w.fullName).join(', '),
            Icons.group_outlined,
          ),
          if (_dueDate != null && _dueTime != null)
            _buildReviewCard(
              'מועד יעד',
              '${DateFormat('dd/MM/yyyy').format(_dueDate!)} ${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}',
              Icons.calendar_today_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: BorderRadius.circular(TaskTheme.radiusL),
        boxShadow: TaskTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TaskTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: TaskTheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TaskTheme.caption),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TaskTheme.label
                      .copyWith(color: TaskTheme.textPrimary),
                ),
              ],
            ),
          ),
          Material(
            color: TaskTheme.background,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (label == 'עובדים') {
                  _goToStep(1);
                } else if (label == 'מועד יעד') {
                  _goToStep(2);
                } else {
                  _goToStep(0);
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.edit_rounded,
                    size: 16, color: TaskTheme.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Buttons ────────────────────────────────────────

  Widget _buildBottomButtons() {
    final isLast = _currentStep == 3;
    final btnColor = isLast ? TaskTheme.done : TaskTheme.primary;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        boxShadow: TaskTheme.topBarShadow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                    border: Border.all(color: TaskTheme.border, width: 1.5),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                      onTap: () => _goToStep(_currentStep - 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.arrow_back_rounded,
                                size: 18, color: TaskTheme.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'חזור',
                              style: TextStyle(
                                fontSize: 15,
                                color: TaskTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                  gradient: LinearGradient(
                    colors: [btnColor, btnColor.withOpacity(0.85)],
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                  boxShadow: TaskTheme.buttonShadow(btnColor),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(TaskTheme.radiusM),
                    onTap: _isSubmitting
                        ? null
                        : () {
                            if (isLast) {
                              _submitTask();
                            } else {
                              _goToStep(_currentStep + 1);
                            }
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLast)
                                    const Icon(Icons.check_circle_rounded,
                                        size: 20, color: Colors.white),
                                  if (isLast) const SizedBox(width: 8),
                                  Text(
                                    isLast ? 'צור משימה' : 'המשך',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  if (!isLast) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 18, color: Colors.white),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitTask() async {
    if (_isSubmitting) return;

    final currentUid = context.read<AppAuthProvider>().uid;
    if (currentUid == null) return;

    if (!_validateStep1() || !_validateStep2() || !_validateStep3()) return;

    setState(() => _isSubmitting = true);

    final dueDateTime = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );

    final now = Timestamp.now();

    final workerProgress = <String, Map<String, dynamic>>{
      for (var user in _selectedWorkers)
        user.uid: {
          'status': 'pending',
          'submittedAt': now,
          'startedAt': null,
          'endedAt': null,
        }
    };

    final newTask = TaskModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      department: _department,
      createdBy: currentUid,
      assignedTo: _selectedWorkers.map((u) => u.uid).toList(),
      dueDate: Timestamp.fromDate(dueDateTime),
      priority: _priority,
      status: 'pending',
      attachments: [],
      comments: [],
      createdAt: now,
      workerProgress: workerProgress,
      updatedAt: now,
    );

    try {
      await _taskService.createTask(newTask);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('שגיאה ביצירת המשימה');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
