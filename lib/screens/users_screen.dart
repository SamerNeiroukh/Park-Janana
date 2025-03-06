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

  // ✅ Cache storage to store fetched users
  static final Map<String, List<UserModel>> _userCache = {};

  @override
  void initState() {
    super.initState();
    fetchAllUsers();
  }

  Future<void> fetchAllUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _userCache.containsKey('allUsers')) {
      // ✅ Use cached users instead of refetching
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
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          filteredUsers = users;
          _isLoading = false;
          _userCache['allUsers'] = users; // ✅ Store in cache
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
    await _workerService.assignWorkerToShift(widget.shiftId, workerId);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("✔️ עובד נוסף למשמרת בהצלחה"),
    ));

    setState(() {
      widget.assignedWorkerIds.add(workerId);
    });
  }

  Future<void> removeWorkerFromShift(String workerId) async {
    await _workerService.removeWorkerFromShift(widget.shiftId, workerId);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("❌ עובד הוסר מהמשמרת"),
    ));

    setState(() {
      widget.assignedWorkerIds.remove(workerId);
    });
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

          // ✅ Pull-to-refresh added
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
                            final bool isAssigned = widget.assignedWorkerIds.contains(worker.uid);

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
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
                                  icon: Icon(
                                    isAssigned ? Icons.person_remove : Icons.person_add,
                                    color: isAssigned ? Colors.red : Colors.green,
                                    size: 24,
                                  ),
                                  onPressed: () {
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
