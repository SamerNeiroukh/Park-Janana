import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/constants/app_colors.dart';
import 'package:park_janana/constants/app_theme.dart';
import 'package:park_janana/widgets/user_header.dart';
import 'package:park_janana/services/auth_service.dart';
import 'package:park_janana/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatefulWidget {
  final QueryDocumentSnapshot userData;

  const UserProfileScreen({super.key, required this.userData});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final AuthService _authService = AuthService();
  String _currentUserRole = '';
  String _selectedRole = '';
  bool _isLoading = true;
  bool _isUpdatingRole = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.userData['role'] ?? 'worker';
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRole = prefs.getString('userRole');
      if (cachedRole != null) {
        setState(() {
          _currentUserRole = cachedRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole() async {
    if (_selectedRole == widget.userData['role']) return;

    setState(() => _isUpdatingRole = true);

    try {
      await _authService.updateUserRole(
        _currentUserRole,
        widget.userData['uid'],
        _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('תפקיד עודכן בהצלחה')),
        );
        Navigator.pop(context, true); // Return true to indicate update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => _isUpdatingRole = false);
    }
  }

  Widget _buildRoleManagementSection() {
    final allowedRoles = _authService.getAllowedRolesToAssign(_currentUserRole);
    
    if (allowedRoles.isEmpty) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'ניהול תפקיד',
                style: AppTheme.sectionTitle.copyWith(fontSize: 18),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'תפקיד נוכחי: ${_getRoleDisplayName(widget.userData['role'])}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'שנה תפקיד:',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedRole,
                isExpanded: true,
                items: allowedRoles.map((role) {
                  return DropdownMenuItem<String>(
                    value: role,
                    child: Text(_getRoleDisplayName(role)),
                  );
                }).toList(),
                onChanged: (String? newRole) {
                  if (newRole != null) {
                    setState(() => _selectedRole = newRole);
                  }
                },
              ),
            ),
          ),
          if (_selectedRole != widget.userData['role']) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUpdatingRole ? null : _updateRole,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUpdatingRole
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'עדכן תפקיד',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'owner':
        return 'בעלים';
      case 'department_manager':
        return 'מנהל מחלקה';
      case 'shift_manager':
        return 'מנהל משמרת';
      case 'worker':
        return 'עובד';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String fullName = widget.userData['fullName'] ?? '';
    final String email = widget.userData['email'] ?? '';
    final String phone = widget.userData['phoneNumber'] ?? '';
    final String id = widget.userData['idNumber'] ?? '';
    final String profilePicture = widget.userData['profile_picture'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    // Profile Picture and Name
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: profilePicture.isNotEmpty
                                ? NetworkImage(profilePicture)
                                : const AssetImage('assets/images/default_profile.png')
                                    as ImageProvider,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getRoleDisplayName(widget.userData['role']),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // User Details
                    Container(
                      padding: const EdgeInsets.all(20),
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
                            '🧾 פרטי העובד',
                            style: AppTheme.sectionTitle.copyWith(fontSize: 18),
                          ),
                          const Divider(height: 24),
                          _buildInfoRow(Icons.email_rounded, "אימייל", email),
                          _buildInfoRow(Icons.phone, "טלפון", phone),
                          _buildInfoRow(Icons.credit_card, "תעודת זהות", id),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Role Management Section
                    _buildRoleManagementSection(),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 12),
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}