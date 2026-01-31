import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/comments_sheet.dart';

class NewsfeedScreen extends StatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  State<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen> {
  final NewsfeedService _newsfeedService = NewsfeedService();
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'value': null, 'label': 'הכל', 'icon': Icons.dashboard_rounded},
    {'value': 'announcement', 'label': 'הודעות', 'icon': Icons.campaign_rounded},
    {'value': 'update', 'label': 'עדכונים', 'icon': Icons.update_rounded},
    {'value': 'event', 'label': 'אירועים', 'icon': Icons.event_rounded},
    {'value': 'general', 'label': 'כללי', 'icon': Icons.article_rounded},
  ];

  bool _isManager(String? role) {
    return role == 'manager' || role == 'admin';
  }

  void _showCreatePostDialog(BuildContext context) {
    final authProvider = context.read<AppAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    showDialog(
      context: context,
      builder: (context) => CreatePostDialog(
        authorId: authProvider.uid ?? '',
        authorName: currentUser?.fullName ?? 'משתמש',
        authorRole: authProvider.userRole ?? 'worker',
        authorProfilePicture: currentUser?.profilePicture ?? '',
      ),
    );
  }

  void _showCommentsSheet(BuildContext context, PostModel post) {
    final authProvider = context.read<AppAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(
        post: post,
        currentUserId: authProvider.uid ?? '',
        currentUserName: currentUser?.fullName ?? 'משתמש',
        currentUserProfilePicture: currentUser?.profilePicture ?? '',
        isManager: _isManager(authProvider.userRole),
      ),
    );
  }

  Future<void> _handleLike(PostModel post, String userId) async {
    try {
      if (post.isLikedBy(userId)) {
        await _newsfeedService.unlikePost(post.id, userId);
      } else {
        await _newsfeedService.likePost(post.id, userId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('מחיקת פוסט'),
              const SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.red),
            ],
          ),
          content: const Text('האם אתה בטוח שברצונך למחוק את הפוסט?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      try {
        await _newsfeedService.deletePost(post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הפוסט נמחק בהצלחה'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('שגיאה במחיקת הפוסט: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _handlePin(PostModel post) async {
    try {
      await _newsfeedService.togglePin(post.id, !post.isPinned);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(post.isPinned ? 'הפוסט הוסר מהנעוצים' : 'הפוסט נועץ'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, child) {
        final isManager = _isManager(authProvider.userRole);
        final userId = authProvider.uid ?? '';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                const UserHeader(),

                // Title and category filter
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title row
                      Row(
                        children: [
                          if (isManager)
                            IconButton(
                              onPressed: () => _showCreatePostDialog(context),
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          const Spacer(),
                          const Text(
                            'לוח מודעות',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SuezOne',
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.newspaper_rounded,
                            color: AppColors.primaryBlue,
                            size: 28,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Category chips
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          reverse: true,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected =
                                _selectedCategory == category['value'];

                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: FilterChip(
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = category['value'];
                                  });
                                },
                                avatar: Icon(
                                  category['icon'] as IconData,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryBlue,
                                ),
                                label: Text(category['label'] as String),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                                backgroundColor: Colors.white,
                                selectedColor: AppColors.primaryBlue,
                                checkmarkColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : AppColors.greyLight,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Posts list
                Expanded(
                  child: StreamBuilder<List<PostModel>>(
                    stream: _selectedCategory == null
                        ? _newsfeedService.getPostsStream()
                        : _newsfeedService
                            .getPostsByCategory(_selectedCategory!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primaryBlue,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppColors.greyMedium,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'שגיאה בטעינת הפוסטים',
                                style: TextStyle(
                                  color: AppColors.greyMedium,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final posts = snapshot.data ?? [];

                      if (posts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 80,
                                color: AppColors.greyLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'אין פוסטים עדיין',
                                style: TextStyle(
                                  color: AppColors.greyMedium,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (isManager)
                                Text(
                                  'לחץ על + כדי לפרסם פוסט ראשון',
                                  style: TextStyle(
                                    color: AppColors.greyMedium,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            return PostCard(
                              post: post,
                              currentUserId: userId,
                              isManager: isManager,
                              onLike: () => _handleLike(post, userId),
                              onComment: () => _showCommentsSheet(context, post),
                              onDelete: () => _handleDelete(post),
                              onPin: () => _handlePin(post),
                              onTap: () => _showCommentsSheet(context, post),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // FAB for managers
            floatingActionButton: isManager
                ? FloatingActionButton.extended(
                    onPressed: () => _showCreatePostDialog(context),
                    backgroundColor: AppColors.primaryBlue,
                    icon: const Icon(Icons.create_rounded, color: Colors.white),
                    label: const Text(
                      'פוסט חדש',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }
}
