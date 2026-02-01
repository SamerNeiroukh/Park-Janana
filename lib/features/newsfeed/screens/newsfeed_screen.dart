import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';
import '../widgets/post_detail_sheet.dart';
import '../widgets/likers_sheet.dart';

class NewsfeedScreen extends StatefulWidget {
  const NewsfeedScreen({super.key});

  @override
  State<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen>
    with SingleTickerProviderStateMixin {
  final NewsfeedService _newsfeedService = NewsfeedService();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  // Cache the stream to avoid recreating it on every build
  Stream<List<PostModel>>? _postsStream;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initStream();
  }

  void _initStream() {
    _postsStream ??= _newsfeedService.getPostsStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showFab = _scrollController.offset < 100;
    if (showFab != _showFab) {
      setState(() => _showFab = showFab);
    }
  }

  bool _isManager(String? role) {
    return role == 'manager' || role == 'admin';
  }

  void _showCreatePostDialog(BuildContext context) {
    HapticFeedback.mediumImpact();
    final authProvider = context.read<AppAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Create Post',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => CreatePostDialog(
        authorId: authProvider.uid ?? '',
        authorName: currentUser?.fullName ?? 'משתמש',
        authorRole: authProvider.userRole ?? 'worker',
        authorProfilePicture: currentUser?.profilePicturePath ?? currentUser?.profilePicture ?? '',
      ),
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
          child: FadeTransition(
            opacity: anim1,
            child: child,
          ),
        );
      },
    );
  }

  void _showPostDetailSheet(BuildContext context, PostModel post, String userId) {
    HapticFeedback.selectionClick();
    final authProvider = context.read<AppAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isManager = _isManager(authProvider.userRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailSheet(
        post: post,
        currentUserId: authProvider.uid ?? '',
        currentUserName: currentUser?.fullName ?? 'משתמש',
        currentUserProfilePicture: currentUser?.profilePicturePath ?? currentUser?.profilePicture ?? '',
        isManager: isManager,
        onLike: () => _handleLike(post, userId),
        onDelete: () => _handleDelete(post),
        onPin: () => _handlePin(post),
        onShowLikers: () => _showLikersSheet(context, post),
      ),
    );
  }

  void _showLikersSheet(BuildContext context, PostModel post) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LikersSheet(
        likedByUserIds: post.likedBy,
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
      if (!mounted) return;
      _showErrorSnackbar('שגיאה: $e');
    }
  }

  Future<void> _handleDelete(PostModel post) async {
    HapticFeedback.mediumImpact();
    final confirm = await _showDeleteDialog();
    if (confirm != true) return;

    try {
      await _newsfeedService.deletePost(post.id);
      if (!mounted) return;
      _showSuccessSnackbar('הפוסט נמחק בהצלחה');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('שגיאה במחיקת הפוסט: $e');
    }
  }

  Future<void> _handlePin(PostModel post) async {
    HapticFeedback.selectionClick();
    try {
      await _newsfeedService.togglePin(post.id, !post.isPinned);
      if (!mounted) return;
      _showSuccessSnackbar(post.isPinned ? 'הפוסט הוסר מהנעוצים' : 'הפוסט ננעץ');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('שגיאה: $e');
    }
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                'מחיקת פוסט',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              ),
            ],
          ),
          content: const Text(
            'האם אתה בטוח שברצונך למחוק את הפוסט?\nפעולה זו לא ניתנת לביטול.',
            textAlign: TextAlign.right,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (context, authProvider, _) {
        final isManager = _isManager(authProvider.userRole);
        final userId = authProvider.uid ?? '';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Stack(
              children: [
                // Background gradient
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryBlue.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.success.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Main content
                Column(
                  children: [
                    const UserHeader(),
                    _buildHeader(),
                    Expanded(
                      child: _buildFeed(isManager, userId),
                    ),
                  ],
                ),
              ],
            ),
            floatingActionButton: isManager
                ? AnimatedSlide(
                    offset: _showFab ? Offset.zero : const Offset(0, 2),
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedOpacity(
                      opacity: _showFab ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: _buildFab(),
                    ),
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.15),
                  AppColors.primaryBlue.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.newspaper_rounded,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.deepBlue],
            ).createShader(bounds),
            child: const Text(
              'לוח מודעות',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'SuezOne',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeed(bool isManager, String userId) {
    return StreamBuilder<List<PostModel>>(
      // Use the cached stream to avoid recreating on every build
      stream: _postsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        if (snapshot.hasError) {
          debugPrint('Newsfeed error: ${snapshot.error}');
          return _ErrorState(onRetry: () {
            setState(() {
              _postsStream = null;
              _initStream();
            });
          });
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return _EmptyState(isManager: isManager);
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            // Force recreate stream to get fresh data
            setState(() {
              _postsStream = null;
              _initStream();
            });
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primaryBlue,
          backgroundColor: Colors.white,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 120),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                key: ValueKey(post.id),
                post: post,
                currentUserId: userId,
                isManager: isManager,
                index: index,
                onLike: () => _handleLike(post, userId),
                onComment: () => _showPostDetailSheet(context, post, userId),
                onDelete: () => _handleDelete(post),
                onPin: () => _handlePin(post),
                onTap: () => _showPostDetailSheet(context, post, userId),
                onShowLikers: () => _showLikersSheet(context, post),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(context),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
        label: const Text(
          'פוסט חדש',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ===============================
// Sub Widgets
// ===============================

class _EmptyState extends StatelessWidget {
  final bool isManager;

  const _EmptyState({required this.isManager});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.primaryBlue.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'אין פוסטים עדיין',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isManager
                ? 'לחץ על "פוסט חדש" כדי לפרסם את הפוסט הראשון'
                : 'המנהלים יפרסמו כאן עדכונים בקרוב',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyMedium.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback? onRetry;

  const _ErrorState({this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_off_rounded,
              size: 56,
              color: Colors.red.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'שגיאה בטעינת הפוסטים',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'בדוק את החיבור לאינטרנט ונסה שוב',
            style: TextStyle(color: AppColors.greyMedium),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('נסה שוב'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
