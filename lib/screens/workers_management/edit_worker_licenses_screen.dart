import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/config/departments.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/widgets/user_header.dart';

class EditWorkerLicensesScreen extends StatefulWidget {
  final String uid;
  final String fullName;

  const EditWorkerLicensesScreen({
    super.key,
    required this.uid,
    required this.fullName,
  });

  @override
  State<EditWorkerLicensesScreen> createState() => _EditWorkerLicensesScreenState();
}

class _EditWorkerLicensesScreenState extends State<EditWorkerLicensesScreen> {
  final List<String> _selectedDepartments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkerLicenses();
  }

  Future<void> _loadWorkerLicenses() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<String> licensed = List<String>.from(data['licensedDepartments'] ?? []);
        setState(() {
          _selectedDepartments.addAll(licensed);
        });
      }
    } catch (e) {
      debugPrint("Error loading licenses: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _toggleDepartment(String dept) {
    setState(() {
      if (_selectedDepartments.contains(dept)) {
        _selectedDepartments.remove(dept);
      } else {
        _selectedDepartments.add(dept);
      }
    });
  }

  Future<void> _saveChanges() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).update({
        'licensedDepartments': _selectedDepartments,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("הרשאות עודכנו בהצלחה")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving licenses: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Directionality(
                    textDirection: TextDirection.rtl,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ניהול הרשאות לעובד",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "בחר מחלקות מורשות",
                                  style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                                ),
                                const Divider(height: 24),
                                ...allDepartments.map((dept) {
                                  final bool selected = _selectedDepartments.contains(dept);
                                  return CheckboxListTile(
                                    value: selected,
                                    onChanged: (_) => _toggleDepartment(dept),
                                    title: Text(
                                      dept,
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                    activeColor: AppColors.primary,
                                    checkboxShape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: SizedBox(
                              width: 260,
                              child: ElevatedButton.icon(
                                onPressed: _saveChanges,
                                icon: const Icon(Icons.save),
                                label: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.0),
                                  child: Text(
                                    "שמור שינויים",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
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
}
