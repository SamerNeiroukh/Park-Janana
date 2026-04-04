import 'package:flutter/material.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/features/workers/services/worker_service.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UsersScreen extends StatefulWidget {
  final String shiftId;
  final List<String> assignedWorkerIds;
  final bool draftMode;

  const UsersScreen({
    super.key,
    required this.shiftId,
    required this.assignedWorkerIds,
    this.draftMode = false,
  });

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  final WorkerService _workerService = WorkerService();
  bool _isLoading = true;

  final Set<String> _inProgressWorkerIds = {};
  final Set<String> _selectedDraftIds = {};
  // Cache is intentionally NOT static-persisted across app sessions.
  // Cleared on every new instance so role changes are always reflected.
  final Map<String, List<UserModel>> _userCache = {};

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _userCache.containsKey('allUsers')) {
      setState(() {
        users = _userCache['allUsers']!;
        filteredUsers = users;
        _isLoading = false;
      });
      return;
    }

    try {
      final List<UserModel> fetchedUsers =
          await _workerService.fetchAllWorkers();
      if (mounted) {
        setState(() {
          users = fetchedUsers;
          filteredUsers = users;
          _isLoading = false;
          _userCache['allUsers'] = users;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("⚠️ Error loading users: $e");
    }
  }

  void filterUsers(String query) {
    final List<UserModel> results = users.where((user) {
      final nameLower = user.fullName.toLowerCase();
      final roleLower = user.role.toLowerCase();
      final searchLower = query.toLowerCase();
      return nameLower.contains(searchLower) || roleLower.contains(searchLower);
    }).toList();

    setState(() {
      filteredUsers = results;
    });
  }

  Future<void> assignWorkerToShift(String workerId) async {
    if (_inProgressWorkerIds.contains(workerId)) return;
    setState(() => _inProgressWorkerIds.add(workerId));

    try {
      await _workerService.assignWorkerToShift(widget.shiftId, workerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).workerAddedToShift)),
        );
        setState(() {
          widget.assignedWorkerIds.add(workerId);
        });
      }
    } finally {
      setState(() => _inProgressWorkerIds.remove(workerId));
    }
  }

  Future<void> removeWorkerFromShift(String workerId) async {
    if (_inProgressWorkerIds.contains(workerId)) return;
    setState(() => _inProgressWorkerIds.add(workerId));

    try {
      await _workerService.removeWorkerFromShift(widget.shiftId, workerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).workerRemovedFromShift)),
        );
        setState(() {
          widget.assignedWorkerIds.remove(workerId);
        });
      }
    } finally {
      setState(() => _inProgressWorkerIds.remove(workerId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: l10n.searchByNameOrRoleHint,
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass),
              ),
              onChanged: filterUsers,
            ),
          ),
          const SizedBox(height: 10.0),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchAllUsers(forceRefresh: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredUsers.isEmpty
                      ? Center(child: Text(l10n.noWorkersFound))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final worker = filteredUsers[index];
                            final isAssigned =
                                widget.assignedWorkerIds.contains(worker.uid);
                            final isDraftSelected =
                                _selectedDraftIds.contains(worker.uid);
                            final isProcessing =
                                _inProgressWorkerIds.contains(worker.uid);

                            return Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 6.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 8.0),
                                leading: ProfileAvatar(
                                  imageUrl: worker.profilePicture,
                                  radius: 30.0,
                                ),
                                title: Text(
                                  worker.fullName,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(worker.role,
                                    textAlign: TextAlign.right),
                                trailing: widget.draftMode
                                    ? Icon(
                                        isAssigned
                                            ? PhosphorIconsFill.checkCircle
                                            : isDraftSelected
                                                ? PhosphorIconsFill.checkCircle
                                                : PhosphorIconsRegular.plusCircle,
                                        color: isAssigned
                                            ? Colors.grey
                                            : isDraftSelected
                                                ? Colors.green
                                                : Colors.green,
                                        size: 28,
                                      )
                                    : IconButton(
                                        icon: isProcessing
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2),
                                              )
                                            : Icon(
                                                isAssigned
                                                    ? PhosphorIconsRegular.userMinus
                                                    : PhosphorIconsRegular.userPlus,
                                                color: isAssigned
                                                    ? Colors.red
                                                    : Colors.green,
                                                size: 24,
                                              ),
                                        onPressed: isProcessing
                                            ? null
                                            : () {
                                                isAssigned
                                                    ? removeWorkerFromShift(
                                                        worker.uid)
                                                    : assignWorkerToShift(worker.uid);
                                              },
                                      ),
                                onTap: widget.draftMode && !isAssigned
                                    ? () {
                                        setState(() {
                                          if (isDraftSelected) {
                                            _selectedDraftIds.remove(worker.uid);
                                          } else {
                                            _selectedDraftIds.add(worker.uid);
                                          }
                                        });
                                      }
                                    : null,
                              ),
                            );
                          },
                        ),
            ),
          ),
          if (widget.draftMode && _selectedDraftIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                elevation: 3,
                shadowColor: Colors.green.withValues(alpha: 0.3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.pop(context, _selectedDraftIds.toList()),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsRegular.userPlus, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            l10n.addWorkersCount(_selectedDraftIds.length),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
          ],
        ),
    );
  }
}
