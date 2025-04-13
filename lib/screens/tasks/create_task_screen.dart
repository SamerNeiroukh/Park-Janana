import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/task_service.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../widgets/user_header.dart';
import '../../constants/app_theme.dart';
import '../../constants/app_colors.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String _priority = 'medium';
  String _department = 'general';

  final TaskService _taskService = TaskService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  final List<UserModel> _selectedWorkers = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    final query = await _firestore.collection('users').get();
    final users = query.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap({...data, 'uid': doc.id});
    }).toList();

    setState(() {
      _allUsers = users;
      _filteredUsers = users;
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
                    Text("פרטי משימה", style: AppTheme.sectionTitle),
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
                      validator: (val) => val == null || val.isEmpty ? "שדה חובה" : null,
                    ),
                    const SizedBox(height: 16),
                    Text("הקצאת עובדים", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: _filterUsers,
                      decoration: AppTheme.inputDecoration(hintText: "🔍 חיפוש לפי שם או תפקיד"),
                    ),

                    const SizedBox(height: 8),

                    // Chips for selected workers
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

                    const SizedBox(height: 12),

                    // Worker cards
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final selected = _isSelected(user);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profilePicture.isNotEmpty
                                  ? NetworkImage(user.profilePicture)
                                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                            title: Text(user.fullName, textAlign: TextAlign.right),
                            subtitle: Text(user.role, textAlign: TextAlign.right),
                            trailing: IconButton(
                              icon: Icon(
                                selected ? Icons.person_remove : Icons.person_add,
                                color: selected ? Colors.red : Colors.green,
                              ),
                              onPressed: () => _toggleUser(user),
                            ),
                          ),
                        );
                      },
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
                      onPressed: _submitTask,
                      style: AppTheme.primaryButtonStyle,
                      child: const Text("יצירת משימה"),
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _dueTime = picked);
  }

  Future<void> _submitTask() async {
    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _dueTime == null ||
        _currentUser == null ||
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

    final newTask = TaskModel(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      department: _department,
      createdBy: _currentUser!.uid,
      assignedTo: _selectedWorkers.map((u) => u.uid).toList(),
      dueDate: Timestamp.fromDate(dueDateTime),
      priority: _priority,
      status: 'pending',
      attachments: [],
      comments: [],
      createdAt: Timestamp.now(),
    );

    await _taskService.createTask(newTask);
    if (mounted) Navigator.pop(context);
  }
}
