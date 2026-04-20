import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/config/departments.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EditWorkerLicensesScreen extends StatefulWidget {
  final String uid;
  final String fullName;
  final String currentUserRole;
  final String currentUserId;

  const EditWorkerLicensesScreen({
    super.key,
    required this.uid,
    required this.fullName,
    this.currentUserRole = 'manager',
    this.currentUserId = '',
  });

  @override
  State<EditWorkerLicensesScreen> createState() =>
      _EditWorkerLicensesScreenState();
}

class _EditWorkerLicensesScreenState extends State<EditWorkerLicensesScreen> {
  final List<String> _selectedDepartments = [];
  String _role = 'worker';
  String _originalRole = 'worker';
  bool _isLoading = true;
  bool _isSaving = false;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _loadWorkerData();
  }

  Future<void> _loadWorkerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(widget.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<String> licensed =
            List<String>.from(data['licensedDepartments'] ?? []);
        final loadedRole = data['role'] as String? ?? 'worker';
        setState(() {
          _selectedDepartments.addAll(licensed);
          _role = loadedRole;
          _originalRole = loadedRole;
        });
      }
    } catch (e) {
      debugPrint("Error loading worker data: $e");
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

  String _roleLabel(String role) {
    switch (role) {
      case 'manager': return _l10n.managerRole;
      case 'co_owner': return _l10n.coOwnerRoleLabel;
      case 'owner': return _l10n.ownerRoleLabel;
      default: return _l10n.workerRoleLabel;
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(widget.uid)
          .update({
        'licensedDepartments': _selectedDepartments,
        'role': _role,
      });

      // Send in-app notification if role changed
      if (_role != _originalRole) {
        await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(widget.uid)
            .collection('notifications')
            .add({
          'type': 'role_changed',
          'title': _l10n.roleChangedTitle,
          'body': _l10n.roleChangedBody(_roleLabel(_originalRole), _roleLabel(_role)),
          'entityId': '',
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(_l10n.licensesUpdated),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error saving: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.saveLicensesError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          const UserHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              // Managers can only manage certificates, not roles.
                              // Owners cannot demote themselves.
                              if (widget.currentUserRole != 'manager' &&
                                  widget.currentUserId != widget.uid) ...[
                                _buildRoleSection(),
                                const SizedBox(height: 16),
                              ],
                              _buildDepartmentsSection(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      _buildSaveBar(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(PhosphorIconsRegular.userGear,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _l10n.managePermissionsButton,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(PhosphorIconsFill.identificationCard,
                    color: Color(0xFF6366F1), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                _l10n.roleSectionTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRoleTile(
                  role: 'worker',
                  label: _l10n.workerRoleLabel,
                  icon: PhosphorIconsRegular.user,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleTile(
                  role: 'manager',
                  label: _l10n.managerRole,
                  icon: PhosphorIconsRegular.users,
                  color: const Color(0xFF6366F1),
                  lockedForNonOwner: widget.currentUserRole != 'owner' &&
                      widget.currentUserRole != 'co_owner',
                ),
              ),
              if (widget.currentUserRole == 'owner') ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRoleTile(
                    role: 'co_owner',
                    label: _l10n.coOwnerRoleLabel,
                    icon: PhosphorIconsRegular.star,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ],
          ),
          if (widget.currentUserRole != 'owner' && widget.currentUserRole != 'co_owner') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(PhosphorIconsRegular.lock,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Text(
                  _l10n.managerRoleUpgradeNote,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleTile({
    required String role,
    required String label,
    required IconData icon,
    required Color color,
    bool lockedForNonOwner = false,
  }) {
    final isSelected = _role == role;
    final isLocked = lockedForNonOwner && !isSelected;

    return GestureDetector(
      onTap: lockedForNonOwner ? null : () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isLocked
              ? const Color(0xFFF1F5F9)
              : isSelected
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLocked
                ? const Color(0xFFE2E8F0)
                : isSelected
                    ? color
                    : const Color(0xFFE2E8F0),
            width: isSelected && !isLocked ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isLocked ? PhosphorIconsRegular.lock : icon,
              color: isLocked
                  ? const Color(0xFFCBD5E1)
                  : isSelected
                      ? color
                      : const Color(0xFF94A3B8),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLocked
                    ? const Color(0xFFCBD5E1)
                    : isSelected
                        ? color
                        : const Color(0xFF64748B),
              ),
            ),
            if (isSelected && !isLocked) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(PhosphorIconsRegular.buildings,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _l10n.authorizedDepartmentsLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_selectedDepartments.length}/${allDepartments.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _l10n.departmentsSectionHint,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          ...allDepartments.map((dept) => _buildDepartmentTile(dept)),
        ],
      ),
    );
  }

  Widget _buildDepartmentTile(String dept) {
    final isSelected = _selectedDepartments.contains(dept);
    final color = getDepartmentColor(dept);
    final icon = getDepartmentIcon(dept);

    return GestureDetector(
      onTap: () => _toggleDepartment(dept),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color:
                      isSelected ? Colors.white : const Color(0xFF94A3B8),
                  size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                getLocalizedDepartmentName(dept, _l10n),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(PhosphorIconsRegular.check,
                      color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            disabledBackgroundColor:
                const Color(0xFF6366F1).withValues(alpha: 0.6),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(PhosphorIconsFill.checkCircle,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _l10n.saveChangesButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
