import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../../models/task_model.dart';
import '../../services/task_service.dart';
import '../../widgets/user_header.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';

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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TaskService _taskService = TaskService();

  List<Map<String, dynamic>> _usernameSuggestions = [];
  final List<Map<String, dynamic>> _selectedWorkers = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _dueDate = widget.task.dueDate.toDate();
    _dueTime = TimeOfDay.fromDateTime(_dueDate!);
    _priority = widget.task.priority;
    _department = widget.task.department;

    for (String uid in widget.task.assignedTo) {
      _firestore.collection('users').doc(uid).get().then((doc) {
        if (doc.exists) {
          setState(() {
            _selectedWorkers.add({
              'uid': doc.id,
              'username': doc['username'] ?? '',
            });
          });
        }
      });
    }
  }

  Future<void> _searchUsernames(String query) async {
    if (query.isEmpty) {
      setState(() => _usernameSuggestions = []);
      return;
    }

    final results = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: query)
        .where('username', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(5)
        .get();

    setState(() {
      _usernameSuggestions = results.docs
          .map((doc) => {
                'uid': doc.id,
                'username': doc['username'] ?? '',
              })
          .toList();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _dueTime == null ||
        _selectedWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("יש למלא את כל השדות ולבחור עובדים")),
      );
      return;
    }

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
      assignedTo: _selectedWorkers.map((u) => u['uid'] as String).toList(),
      dueDate: Timestamp.fromDate(dueDateTime),
      priority: _priority,
      status: widget.task.status,
      attachments: widget.task.attachments,
      comments: widget.task.comments,
      createdAt: widget.task.createdAt,
    );

    await _taskService.updateTask(updatedTask.id, updatedTask.toMap());

    if (mounted) Navigator.pop(context);
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
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("עריכת משימה", style: AppTheme.screenTitle),
                    const SizedBox(height: 16),
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
                      validator: (val) => val == null || val.isEmpty ? "שדה חובה" : null,
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _searchController,
                      decoration: AppTheme.inputDecoration(hintText: "חפש שם משתמש"),
                      onChanged: _searchUsernames,
                    ),

                    if (_usernameSuggestions.isNotEmpty)
                      ..._usernameSuggestions.map((user) => ListTile(
                            title: Text(user['username']),
                            trailing: const Icon(Icons.person_add, color: AppColors.primary),
                            onTap: () {
                              if (!_selectedWorkers.any((u) => u['uid'] == user['uid'])) {
                                setState(() {
                                  _selectedWorkers.add(user);
                                  _searchController.clear();
                                  _usernameSuggestions.clear();
                                });
                              }
                            },
                          )),

                    Wrap(
                      spacing: 8.0,
                      children: _selectedWorkers
                          .map((user) => Chip(
                                label: Text(user['username']),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () {
                                  setState(() {
                                    _selectedWorkers.removeWhere((u) => u['uid'] == user['uid']);
                                  });
                                },
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 12),
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
                            child: Text(
                              _dueDate == null
                                  ? "בחר תאריך"
                                  : "${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickTime,
                            child: Text(
                              _dueTime == null
                                  ? "בחר שעה"
                                  : "${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitTask,
                      style: AppTheme.primaryButtonStyle,
                      child: const Text("💾 שמור שינויים"),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
