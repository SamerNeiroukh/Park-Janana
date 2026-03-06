import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/models/user_model.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/widgets/profile_avatar.dart';

class LikersSheet extends StatefulWidget {
  final List<String> likedByUserIds;
  final Map<String, List<String>> reactions;

  const LikersSheet({
    super.key,
    required this.likedByUserIds,
    this.reactions = const {},
  });

  @override
  State<LikersSheet> createState() => _LikersSheetState();
}

class _LikersSheetState extends State<LikersSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  List<UserModel> _users = [];
  // userId → set of reaction keys ('like', 'thumbs', 'party')
  Map<String, Set<String>> _userReactionTypes = {};
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
    // Build reaction type map first
    final Map<String, Set<String>> reactionTypes = {};
    for (final uid in widget.likedByUserIds) {
      reactionTypes.putIfAbsent(uid, () => {}).add('like');
    }
    for (final entry in widget.reactions.entries) {
      for (final uid in entry.value) {
        reactionTypes.putIfAbsent(uid, () => {}).add(entry.key);
      }
    }

    final allIds = reactionTypes.keys.toList();
    if (allIds.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final List<UserModel> users = [];

      // Fetch users in batches of 30 (Firestore whereIn limit)
      for (var i = 0; i < allIds.length; i += 30) {
        final batch = allIds.skip(i).take(30).toList();
        final snapshot = await FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in snapshot.docs) {
          users.add(UserModel.fromMap({...doc.data(), 'uid': doc.id}));
        }
      }

      if (mounted) {
        setState(() {
          _users = users;
          _userReactionTypes = reactionTypes;
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

  int get _totalReactors {
    final allIds = <String>{
      ...widget.likedByUserIds,
      for (final v in widget.reactions.values) ...v,
    };
    return allIds.length;
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.withOpacity(0.15),
                      Colors.red.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('❤️ 👍 🎉', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'תגובות לפוסט',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_totalReactors אנשים',
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
        final user = _users[index];
        return _LikerCard(
          user: user,
          reactionTypes: _userReactionTypes[user.uid] ?? {},
        );
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
class _LikerCard extends StatelessWidget {
  final UserModel user;
  final Set<String> reactionTypes;

  const _LikerCard({required this.user, this.reactionTypes = const {}});

  String _reactionEmojis() {
    final emojis = <String>[];
    if (reactionTypes.contains('like')) emojis.add('❤️');
    if (reactionTypes.contains('thumbs')) emojis.add('👍');
    if (reactionTypes.contains('party')) emojis.add('🎉');
    return emojis.join(' ');
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
        border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
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
            child: ProfileAvatar(
              imageUrl: user.profilePicture,
              radius: 22,
              backgroundColor: AppColors.greyLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getRoleDisplayName(user.role),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greyMedium.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _reactionEmojis(),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
