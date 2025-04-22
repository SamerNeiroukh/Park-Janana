import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/worker_service.dart';
import '../widgets/user_header.dart';

class UsersScreen extends StatefulWidget {
  final String shiftId;
  final List<String> assignedWorkerIds;

  const UsersScreen({super.key, required this.shiftId, required this.assignedWorkerIds});

  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  final WorkerService _workerService = WorkerService();
  bool _isLoading = true;

  // ✅ Track which workers are being processed to prevent double taps
  final Set<String> _inProgressWorkerIds = {};

  // ✅ Cache storage to store fetched users
  static final Map<String, List<UserModel>> _userCache = {};

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
      var snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<UserModel> fetchedUsers = snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data());
      }).toList();

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          filteredUsers = users;
          _isLoading = false;
          _userCache['allUsers'] = users;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void filterUsers(String query) {
    List<UserModel> results = users.where((user) {
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
          const SnackBar(content: Text("✔️ עובד נוסף למשמרת בהצלחה")),
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
          const SnackBar(content: Text("❌ עובד הוסר מהמשמרת")),
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
    return Scaffold(
      body: Column(
        children: [
          const UserHeader(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "🔍 חיפוש לפי שם או תפקיד",
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                prefixIcon: const Icon(Icons.search),
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
                      ? const Center(child: Text("⚠️ לא נמצאו עובדים"))
                      : ListView.builder(
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final worker = filteredUsers[index];
                            final isAssigned = widget.assignedWorkerIds.contains(worker.uid);
                            final isProcessing = _inProgressWorkerIds.contains(worker.uid);

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                                trailing: CircleAvatar(
                                  radius: 30.0,
                                  backgroundImage: worker.profilePicture.isNotEmpty &&
                                          worker.profilePicture.startsWith('http')
                                      ? NetworkImage(worker.profilePicture)
                                      : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                                ),
                                title: Text(
                                  worker.fullName,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(worker.role, textAlign: TextAlign.right),
                                leading: IconButton(
                                  icon: isProcessing
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Icon(
                                          isAssigned ? Icons.person_remove : Icons.person_add,
                                          color: isAssigned ? Colors.red : Colors.green,
                                          size: 24,
                                        ),
                                  onPressed: isProcessing
                                      ? null
                                      : () {
                                          isAssigned
                                              ? removeWorkerFromShift(worker.uid)
                                              : assignWorkerToShift(worker.uid);
                                        },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
