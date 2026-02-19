import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class EditTaskScreen extends StatefulWidget {
  final TaskModel task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _priority = 'medium';
  String _department = 'general';

  final TaskService _taskService = TaskService();

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  final List<UserModel> _selectedWorkers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeForm() async {
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _department = widget.task.department;
    _priority = widget.task.priority;
    final due = widget.task.dueDate.toDate();
    _dueDate = DateTime(due.year, due.month, due.day);
    _dueTime = TimeOfDay(hour: due.hour, minute: due.minute);

    final query = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .get();
    final users = query.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap({...data, 'uid': doc.id});
    }).toList();

    if (mounted) {
      setState(() {
        _allUsers = users;
        _filteredUsers = users;
        _selectedWorkers.addAll(
          users.where((u) => widget.task.assignedTo.contains(u.uid)),
        );
      });
    }
  }

  void _filterUsers(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredUsers = _allUsers
          .where((u) =>
              u.fullName.toLowerCase().contains(lower) ||
              u.role.toLowerCase().contains(lower))
          .toList();
    });
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
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Basic Info ─────────────────────
                        const Text('פרטי המשימה', style: TaskTheme.heading2),
                        const SizedBox(height: 16),

                        _buildLabel('כותרת'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _titleController,
                          hint: 'שם המשימה',
                          validator: (v) =>
                              v == null || v.isEmpty ? 'שדה חובה' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('תיאור'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _descriptionController,
                          hint: 'תיאור מפורט',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('עדיפות'),
                        const SizedBox(height: 8),
                        _buildPrioritySelector(),
                        const SizedBox(height: 16),

                        _buildLabel('מחלקה'),
                        const SizedBox(height: 8),
                        _buildDepartmentSelector(),
                        const SizedBox(height: 24),

                        // ─── Deadline ───────────────────────
                        const Text('מועד יעד', style: TaskTheme.heading2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPickerTile(
                                icon: Icons.calendar_today_rounded,
                                value: _dueDate != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(_dueDate!)
                                    : 'תאריך',
                                onTap: _pickDate,
                                isSet: _dueDate != null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildPickerTile(
                                icon: Icons.access_time_rounded,
                                value: _dueTime != null
                                    ? '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}'
                                    : 'שעה',
                                onTap: _pickTime,
                                isSet: _dueTime != null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ─── Workers ────────────────────────
                        const Text('עובדים משובצים', style: TaskTheme.heading2),
                        const SizedBox(height: 12),

                        // Selected chips
                        if (_selectedWorkers.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedWorkers.map((w) {
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
                                    ProfileAvatar(
                                      imageUrl: w.profilePicture,
                                      radius: 12,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      w.fullName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: TaskTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _selectedWorkers.removeWhere(
                                              (u) => u.uid == w.uid)),
                                      child: const Icon(Icons.close_rounded,
                                          size: 14, color: TaskTheme.primary),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Search
                        Container(
                          decoration: BoxDecoration(
                            color: TaskTheme.surface,
                            borderRadius:
                                BorderRadius.circular(TaskTheme.radiusM),
                            border: Border.all(color: TaskTheme.border),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _filterUsers,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'חיפוש עובד...',
                              hintStyle:
                                  TextStyle(color: TaskTheme.textTertiary),
                              prefixIcon: Icon(Icons.search_rounded,
                                  size: 20, color: TaskTheme.textTertiary),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Worker list (limited height)
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, i) {
                              final user = _filteredUsers[i];
                              final isSelected = _selectedWorkers
                                  .any((u) => u.uid == user.uid);

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedWorkers
                                          .removeWhere((u) => u.uid == user.uid);
                                    } else {
                                      _selectedWorkers.add(user);
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? TaskTheme.primary.withOpacity(0.06)
                                        : TaskTheme.surface,
                                    borderRadius: BorderRadius.circular(
                                        TaskTheme.radiusM),
                                    border: Border.all(
                                      color: isSelected
                                          ? TaskTheme.primary
                                          : TaskTheme.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ProfileAvatar(
                                        imageUrl: user.profilePicture,
                                        radius: 16,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(user.fullName,
                                                style: TaskTheme.label),
                                            Text(user.role,
                                                style: TaskTheme.caption),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.check_circle_rounded
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? TaskTheme.primary
                                            : TaskTheme.textTertiary,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            _buildBottomBar(),
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
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color:
                    isSelected ? color.withOpacity(0.1) : TaskTheme.surface,
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
                        color:
                            isSelected ? color : TaskTheme.textSecondary,
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
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                color:
                    isSelected ? TaskTheme.primary : TaskTheme.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
    required bool isSet,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TaskTheme.surface,
          borderRadius: BorderRadius.circular(TaskTheme.radiusM),
          border: Border.all(
            color: isSet ? TaskTheme.primary : TaskTheme.border,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: TaskTheme.primary),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color:
                    isSet ? TaskTheme.textPrimary : TaskTheme.textTertiary,
              ),
            ),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: TaskTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: TaskTheme.topBarShadow,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(TaskTheme.radiusM),
            gradient: const LinearGradient(
              colors: [TaskTheme.primary, Color(0xFF5B8DEF)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
            ),
            boxShadow: TaskTheme.buttonShadow(TaskTheme.primary),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(TaskTheme.radiusM),
            child: InkWell(
              borderRadius: BorderRadius.circular(TaskTheme.radiusM),
              onTap: _isSubmitting ? null : _submitEdit,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.save_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'שמור שינויים',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEdit() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _dueTime == null ||
        _selectedWorkers.isEmpty) {
      _showError('יש למלא את כל השדות ולבחור עובדים');
      return;
    }

    setState(() => _isSubmitting = true);

    final dueDateTime = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );

    final now = Timestamp.now();
    final updatedWorkerProgress = <String, Map<String, dynamic>>{};

    for (var user in _selectedWorkers) {
      final existing = widget.task.workerProgress[user.uid];
      updatedWorkerProgress[user.uid] = {
        'status': existing?['status'] ?? 'pending',
        'submittedAt': existing?['submittedAt'] ?? now,
        'startedAt': existing?['startedAt'],
        'endedAt': existing?['endedAt'],
      };
    }

    final updatedData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'department': _department,
      'priority': _priority,
      'assignedTo': _selectedWorkers.map((u) => u.uid).toList(),
      'dueDate': Timestamp.fromDate(dueDateTime),
      'workerProgress': updatedWorkerProgress,
      'updatedAt': now,
    };

    final uid = context.read<AppAuthProvider>().uid;

    try {
      await _taskService.updateTask(widget.task.id, updatedData);
      if (uid != null) {
        await _taskService.logActivity(
          widget.task.id,
          action: 'edited',
          by: uid,
          details: 'המשימה עודכנה',
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('שגיאה בעדכון המשימה');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
