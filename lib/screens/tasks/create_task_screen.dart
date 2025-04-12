import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/task_model.dart';
import '../../models/user_model.dart';
import '../../services/task_service.dart';
import '../../services/worker_service.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_theme.dart';
import '../../widgets/date_time_picker.dart';
import '../../widgets/user_header.dart';
import '../../widgets/worker_row.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final TaskService _taskService = TaskService();
  final WorkerService _workerService = WorkerService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDeadline = DateTime.now();
  UserModel? _selectedWorker;
  TaskPriority _selectedPriority = TaskPriority.medium;
  List<UserModel> _workers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  // ✅ Fetch Workers List
  void _fetchWorkers() async {
    try {
      List<UserModel> workers = await _workerService.fetchAllWorkers();
      if (mounted) {
        setState(() {
          _workers = workers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching workers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ שגיאה בטעינת רשימת העובדים")),
        );
      }
    }
  }

  // ✅ Create Task
  void _createTask() async {
    if (_titleController.text.isEmpty || _selectedWorker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ נא למלא את כל השדות!")),
      );
      return;
    }

    TaskModel newTask = TaskModel(
      id: FirebaseFirestore.instance.collection('tasks').doc().id,
      title: _titleController.text,
      description: _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : "אין תיאור",
      assignedWorkerId: _selectedWorker!.uid,
      deadline: _selectedDeadline,
      priority: _selectedPriority,
      status: TaskStatus.notStarted,
    );

    await _taskService.createTask(newTask);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ המשימה נוספה בהצלחה!")),
      );
    }
  }

  // ✅ Show Worker Selection Modal
  void _showWorkerSelectionModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SizedBox(
          height: 500,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "בחר עובד",
                  style: AppTheme.sectionTitle,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: _workers.isEmpty
                    ? const Center(child: Text("לא נמצאו עובדים"))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _workers.length,
                        itemBuilder: (context, index) {
                          UserModel worker = _workers[index];
                          return WorkerRow(
                            worker: worker,
                            shiftId: "", // 🔥 Fixed missing required argument
                            isAssigned: false, // 🔥 Fixed missing required argument
                            workerService: _workerService, // 🔥 Fixed missing required argument
                            isApproved: false, // 🔥 Fixed missing required argument
                            onApproveToggle: (bool approved) {}, // 🔥 Corrected function type
                            showRemoveIcon: false, // 🔥 Fixed missing required argument
                            onTap: () { // ✅ Ensure onTap is correctly handled
                              setState(() {
                                _selectedWorker = worker;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: UserHeader(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📝 Task Title
                    const Text("כותרת המשימה", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      decoration: AppTheme.inputDecoration(hintText: "הזן כותרת"),
                    ),
                    const SizedBox(height: 20),

                    // 📜 Task Description (Optional)
                    const Text("תיאור המשימה (לא חובה)", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      decoration: AppTheme.inputDecoration(hintText: "הזן תיאור (לא חובה)"),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),

                    // 👥 Assign Worker (Now using Modal)
                    const Text("הקצה לעובד", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _showWorkerSelectionModal,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedWorker != null
                                  ? _selectedWorker!.fullName
                                  : "בחר עובד",
                              style: AppTheme.bodyText,
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ⏳ Deadline Picker
                    const Text("מועד סיום", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    DatePickerWidget(
                      initialDate: _selectedDeadline,
                      onDateSelected: (date) => setState(() {
                        _selectedDeadline = date;
                      }),
                    ),
                    const SizedBox(height: 20),

                    // 🔥 Priority Selection
                    const Text("עדיפות", style: AppTheme.sectionTitle),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: AppTheme.inputDecoration(hintText: "בחר עדיפות"),
                      isExpanded: true,
                      onChanged: (TaskPriority? newValue) {
                        setState(() {
                          _selectedPriority = newValue!;
                        });
                      },
                      items: TaskPriority.values
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority.name.toUpperCase()),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 30),

                    // ✅ Create Task Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: AppTheme.primaryButtonStyle,
                        onPressed: _createTask,
                        icon: const Icon(Icons.add_task),
                        label: const Text("צור משימה"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
