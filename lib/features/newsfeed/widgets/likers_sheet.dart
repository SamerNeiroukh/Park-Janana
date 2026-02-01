import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/models/user_model.dart';

class LikersSheet extends StatefulWidget {
  final List<String> likedByUserIds;

  const LikersSheet({
    super.key,
    required this.likedByUserIds,
  });

  @override
  State<LikersSheet> createState() => _LikersSheetState();
}

class _LikersSheetState extends State<LikersSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
    _fetchUsers();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (widget.likedByUserIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final List<UserModel> users = [];

      // Fetch users in batches of 10 (Firestore whereIn limit)
      for (var i = 0; i < widget.likedByUserIds.length; i += 10) {
        final batch = widget.likedByUserIds.skip(i).take(10).toList();
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          users.add(UserModel.fromMap({...doc.data(), 'uid': doc.id}));
        }
      }

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching likers: $e');
      if (mounted) {
        setState(() {
          _error = 'שגיאה בטעינת הנתונים';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(),
            _buildHeader(),
            const Divider(height: 1),
            Flexible(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.greyMedium.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.15),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'אהבו את הפוסט',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.likedByUserIds.length} אנשים',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyMedium.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Material(
            color: AppColors.greyLight.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.greyMedium.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: AppColors.greyMedium.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return const _EmptyLikers();
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        return _LikerCard(user: _users[index]);
      },
    );
  }
}

// ===============================
// Empty State
// ===============================
class _EmptyLikers extends StatelessWidget {
  const _EmptyLikers();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 40,
              color: AppColors.greyMedium.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'עדיין אין לייקים',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.greyMedium.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'היה הראשון לאהוב את הפוסט!',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.greyMedium.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// Liker Card
// ===============================
class _LikerCard extends StatefulWidget {
  final UserModel user;

  const _LikerCard({required this.user});

  @override
  State<_LikerCard> createState() => _LikerCardState();
}

class _LikerCardState extends State<_LikerCard> {
  String? _resolvedProfileUrl;
  bool _isLoadingPic = true;

  @override
  void initState() {
    super.initState();
    _resolveProfilePicture();
  }

  Future<void> _resolveProfilePicture() async {
    final picPath = widget.user.profilePicturePath ?? widget.user.profilePicture;

    if (picPath.isEmpty) {
      setState(() => _isLoadingPic = false);
      return;
    }

    if (picPath.startsWith('http')) {
      setState(() {
        _resolvedProfileUrl = picPath;
        _isLoadingPic = false;
      });
      return;
    }

    try {
      final ref = FirebaseStorage.instance.ref(picPath);
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() {
          _resolvedProfileUrl = url;
          _isLoadingPic = false;
        });
      }
    } catch (e) {
      debugPrint('Error resolving profile picture: $e');
      if (mounted) {
        setState(() => _isLoadingPic = false);
      }
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'manager':
        return 'מנהל';
      case 'worker':
        return 'עובד';
      case 'admin':
        return 'מנהל מערכת';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.greyLight.withOpacity(0.5),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _buildAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getRoleDisplayName(widget.user.role),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greyMedium.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.favorite_rounded,
            size: 18,
            color: Colors.red.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.greyLight,
        backgroundImage: _resolvedProfileUrl != null
            ? CachedNetworkImageProvider(_resolvedProfileUrl!)
            : null,
        child: _isLoadingPic
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue.withOpacity(0.5),
                ),
              )
            : (_resolvedProfileUrl == null
                ? Text(
                    widget.user.fullName.isNotEmpty
                        ? widget.user.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null),
      ),
    );
  }
}
