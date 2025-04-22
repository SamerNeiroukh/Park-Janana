// unchanged import statements
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_header.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_colors.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<UserModel> _selectedWorkers = [];

  bool _isSubmitting = false; // ✅ Anti-double-tap flag

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _department = widget.task.department;
    _priority = widget.task.priority;
    final due = widget.task.dueDate.toDate();
    _dueDate = DateTime(due.year, due.month, due.day);
    _dueTime = TimeOfDay(hour: due.hour, minute: due.minute);

    final query = await _firestore.collection('users').get();
    final users = query.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap({...data, 'uid': doc.id});
    }).toList();

    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _selectedWorkers = users.where((u) => widget.task.assignedTo.contains(u.uid)).toList();
    });
  }

  void _filterUsers(String query) {
    final lower = query.toLowerCase();
    final filtered = _allUsers.where((user) {
      return user.fullName.toLowerCase().contains(lower) || user.role.toLowerCase().contains(lower);
    }).toList();
    setState(() => _filteredUsers = filtered);
  }

  void _toggleUser(UserModel user) {
    setState(() {
      if (_selectedWorkers.any((u) => u.uid == user.uid)) {
        _selectedWorkers.removeWhere((u) => u.uid == user.uid);
      } else {
        _selectedWorkers.add(user);
      }
    });
  }

  bool _isSelected(UserModel user) {
    return _selectedWorkers.any((u) => u.uid == user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("עריכת משימה", style: AppTheme.sectionTitle),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _titleController,
                      decoration: AppTheme.inputDecoration(hintText: "כותרת המשימה"),
                      validator: (val) => val == null || val.isEmpty ? "שדה חובה" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: AppTheme.inputDecoration(hintText: "תיאור המשימה"),
                    ),
                    const SizedBox(height: 16),
                    Text("הקצאת עובדים", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    Autocomplete<UserModel>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<UserModel>.empty();
                        }
                        return _allUsers.where((user) =>
                          user.fullName.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                          user.role.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      displayStringForOption: (UserModel user) => user.fullName,
                      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                        _searchController.text = controller.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: AppTheme.inputDecoration(hintText: "🔍 חיפוש לפי שם או תפקיד"),
                        );
                      },
                      onSelected: (UserModel user) {
                        _toggleUser(user);
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topRight,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              height: 200.0,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final UserModel user = options.elementAt(index);
                                  final selected = _isSelected(user);
                                  return ListTile(
                                    title: Text(user.fullName),
                                    subtitle: Text(user.role),
                                    trailing: Icon(
                                      selected ? Icons.check_circle : Icons.person_add,
                                      color: selected ? Colors.green : null,
                                    ),
                                    onTap: () => onSelected(user),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_selectedWorkers.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: _selectedWorkers.map((user) {
                          return Chip(
                            label: Text(user.fullName),
                            deleteIcon: const Icon(Icons.close),
                            onDeleted: () => _toggleUser(user),
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: AppTheme.inputDecoration(hintText: "עדיפות"),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('נמוכה')),
                        DropdownMenuItem(value: 'medium', child: Text('בינונית')),
                        DropdownMenuItem(value: 'high', child: Text('גבוהה')),
                      ],
                      onChanged: (val) => setState(() => _priority = val ?? 'medium'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _department,
                      decoration: AppTheme.inputDecoration(hintText: "מחלקה"),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('כללי')),
                        DropdownMenuItem(value: 'paintball', child: Text('פיינטבול')),
                        DropdownMenuItem(value: 'ropes', child: Text('פארק חבלים')),
                        DropdownMenuItem(value: 'carting', child: Text('קרטינג')),
                        DropdownMenuItem(value: 'water_park', child: Text('פארק מים')),
                        DropdownMenuItem(value: 'jimbory', child: Text('ג׳ימבורי')),
                      ],
                      onChanged: (val) => setState(() => _department = val ?? 'general'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text(_dueDate == null
                                ? "בחר תאריך"
                                : "${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTime,
                            child: Text(_dueTime == null
                                ? "בחר שעה"
                                : "${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitEdit, // ✅ Disabled during submission
                      style: AppTheme.primaryButtonStyle,
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text("עדכון משימה"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _dueTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _submitEdit() async {
    if (_isSubmitting) return; // ✅ Prevent double submission

    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _dueTime == null ||
        _selectedWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("יש למלא את כל השדות ולבחור עובדים")),
      );
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

    final updatedTask = TaskModel(
      id: widget.task.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      department: _department,
      createdBy: widget.task.createdBy,
      assignedTo: _selectedWorkers.map((u) => u.uid).toList(),
      dueDate: Timestamp.fromDate(dueDateTime),
      priority: _priority,
      status: widget.task.status,
      attachments: widget.task.attachments,
      comments: widget.task.comments,
      createdAt: widget.task.createdAt,
      workerStatuses: {
        for (var user in _selectedWorkers)
          user.uid: widget.task.workerStatuses[user.uid] ?? 'pending'
      },
    );

    await _taskService.updateTask(widget.task.id, updatedTask.toMap());

    if (mounted) {
      Navigator.pop(context);
    }

    setState(() => _isSubmitting = false);
  }
}
