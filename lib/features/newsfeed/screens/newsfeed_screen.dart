import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import 'package:park_janana/features/auth/providers/auth_provider.dart';
import 'package:park_janana/features/home/providers/user_provider.dart';
import 'package:park_janana/features/home/widgets/user_header.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';
import '../widgets/post_card.dart';
import '../widgets/create_post_dialog.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import '../widgets/post_detail_sheet.dart';
import '../widgets/likers_sheet.dart';

class NewsfeedScreen extends StatefulWidget {
  final String? initialPostId;
  const NewsfeedScreen({super.key, this.initialPostId});

  @override
  State<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends State<NewsfeedScreen>
    with SingleTickerProviderStateMixin {
  final NewsfeedService _newsfeedService = NewsfeedService();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;
  late AppLocalizations _l10n;

  // Pagination
  static const int _pageSize = 10;
  int _postLimit = _pageSize;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Category filter
  String _selectedCategory = 'all';

  // Cached stream
  Stream<List<PostModel>>? _postsStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _initStream();
    if (widget.initialPostId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openInitialPost());
    }
  }

  Future<void> _openInitialPost() async {
    if (!mounted || widget.initialPostId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.postsCollection)
          .doc(widget.initialPostId)
          .get();
      if (!doc.exists || !mounted) return;
      final post = PostModel.fromFirestore(doc);
      final uid = context.read<AppAuthProvider>().uid ?? '';
      _showPostDetailSheet(context, post, uid, openComments: true);
    } catch (e) {
      debugPrint('_openInitialPost error: $e');
    }
  }

  void _initStream() {
    _postsStream = _selectedCategory == 'all'
        ? _newsfeedService.getPostsStream(limit: _postLimit)
        : _newsfeedService.getPostsByCategory(_selectedCategory, limit: _postLimit);
  }

  void _onCategoryChanged(String category) {
    if (_selectedCategory == category) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
      _postLimit = _pageSize;
      _hasMorePosts = true;
      _initStream();
    });
    // Scroll to top after state update
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showFab = _scrollController.offset < 100;
    if (showFab != _showFab) {
      setState(() => _showFab = showFab);
    }

    // Load more posts when near bottom
    if (!_isLoadingMore &&
        _hasMorePosts &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  void _loadMorePosts() {
    _isLoadingMore = true;
    setState(() {
      _postLimit += _pageSize;
      _initStream();
    });
  }

  bool _isManager(String? role) {
    return role == 'manager' || role == 'owner' || role == 'co_owner';
  }

  bool _isOwner(String? role) {
    return role == 'owner' || role == 'co_owner';
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
        authorName: currentUser?.fullName ?? _l10n.defaultUserName,
        authorRole: authProvider.userRole ?? 'worker',
        authorProfilePicture: currentUser?.profilePicture ?? '',
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

  void _showPostDetailSheet(BuildContext context, PostModel post, String userId,
      {bool openComments = false}) {
    HapticFeedback.selectionClick();
    final authProvider = context.read<AppAuthProvider>();
    final userProvider = context.read<UserProvider>();
    final currentUser = userProvider.currentUser;
    final isManager = _isManager(authProvider.userRole);
    final isOwner = _isOwner(authProvider.userRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostDetailSheet(
        post: post,
        currentUserId: authProvider.uid ?? '',
        currentUserName: currentUser?.fullName ?? _l10n.defaultUserName,
        currentUserProfilePicture: currentUser?.profilePicture ?? '',
        isManager: isManager,
        isOwner: isOwner,
        openComments: openComments,
        onLike: () => _handleLike(post, userId),
        onReact: (key) => _handleReact(post, key, userId),
        onDelete: () => _deletePostDirectly(post),
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
        reactions: post.reactions,
      ),
    );
  }

  Future<void> _handleLike(PostModel post, String userId) async {
    try {
      await _newsfeedService.setReaction(post.id, userId, 'love');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(_l10n.genericError(e.toString()));
    }
  }

  Future<void> _handleReact(
      PostModel post, String reactionKey, String userId) async {
    try {
      await _newsfeedService.setReaction(post.id, userId, reactionKey);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(_l10n.genericError(e.toString()));
    }
  }

  Future<void> _handleDelete(PostModel post) async {
    debugPrint('[DELETE] PostCard path: _handleDelete called for post ${post.id}');
    HapticFeedback.mediumImpact();
    final confirm = await _showDeleteDialog();
    debugPrint('[DELETE] PostCard path: dialog returned confirm=$confirm');
    if (confirm != true) return;

    try {
      debugPrint('[DELETE] PostCard path: calling deletePost');
      await _newsfeedService.deletePost(post);
      debugPrint('[DELETE] PostCard path: deletePost done. mounted=$mounted');
      if (!mounted) return;
      _showSuccessSnackbar(_l10n.postDeletedSuccess);
    } catch (e) {
      debugPrint('[DELETE] PostCard path ERROR: $e');
      if (!mounted) return;
      _showErrorSnackbar(_l10n.deletePostError(e.toString()));
    }
  }

  /// Called by PostDetailSheet after it has already shown its own
  /// confirmation dialog — so we just delete directly with no extra dialog.
  Future<void> _deletePostDirectly(PostModel post) async {
    debugPrint('[DELETE] Step 5: _deletePostDirectly called for post ${post.id}');
    try {
      debugPrint('[DELETE] Step 6: calling newsfeedService.deletePost');
      await _newsfeedService.deletePost(post);
      debugPrint('[DELETE] Step 7: deletePost completed. mounted=$mounted');
      if (!mounted) return;
      _showSuccessSnackbar(_l10n.postDeletedSuccess);
    } catch (e) {
      debugPrint('[DELETE] ERROR in _deletePostDirectly: $e');
      if (!mounted) return;
      _showErrorSnackbar(_l10n.deletePostError(e.toString()));
    }
  }

  Future<void> _handlePin(PostModel post) async {
    HapticFeedback.selectionClick();
    try {
      await _newsfeedService.togglePin(post.id, !post.isPinned);
      if (!mounted) return;
      _showSuccessSnackbar(post.isPinned ? _l10n.postUnpinnedSuccess : _l10n.postPinnedSuccess);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(_l10n.genericError(e.toString()));
    }
  }

  Future<bool?> _showDeleteDialog() => showAppDialog(
        context,
        title: _l10n.deletePostTitle,
        message: _l10n.deletePostMessage,
        confirmText: _l10n.deletePostAction,
        icon: PhosphorIconsRegular.trash,
        isDestructive: true,
      );

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(PhosphorIconsFill.checkCircle, color: Colors.white, size: 20),
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
            const Icon(PhosphorIconsRegular.warningCircle, color: Colors.white, size: 20),
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
        final isOwner = _isOwner(authProvider.userRole);
        final userId = authProvider.uid ?? '';

        return Scaffold(
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
                          AppColors.primaryBlue.withValues(alpha: 0.1),
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
                          AppColors.success.withValues(alpha: 0.08),
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
                    _buildSearchBar(),
                    _buildCategoryFilters(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _buildFeed(isManager, isOwner, userId),
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
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
          decoration: InputDecoration(
            hintText: _l10n.searchPostHint,
            prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass, color: AppColors.primaryBlue),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(PhosphorIconsRegular.x, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      {'value': 'all', 'label': _l10n.filterAll, 'icon': PhosphorIconsRegular.tray},
      {'value': 'announcement', 'label': _l10n.categoryAnnouncements, 'icon': PhosphorIconsFill.megaphone},
      {'value': 'update', 'label': _l10n.categoryUpdates, 'icon': PhosphorIconsRegular.arrowsClockwise},
      {'value': 'event', 'label': _l10n.categoryEvents, 'icon': PhosphorIconsRegular.calendarBlank},
      {'value': 'general', 'label': _l10n.categoryGeneral, 'icon': PhosphorIconsRegular.article},
    ];
    final colors = [
      AppColors.primaryBlue,
      AppColors.salmon,
      AppColors.primaryBlue,
      AppColors.success,
      AppColors.greyMedium,
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat['value'];
            final color = colors[index];

            return GestureDetector(
              onTap: () => _onCategoryChanged(cat['value'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected ? Colors.transparent : color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 15,
                      color: isSelected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withValues(alpha: 0.15),
                  AppColors.primaryBlue.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsRegular.newspaper,
              color: AppColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 10),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.primaryBlue, AppColors.deepBlue],
            ).createShader(bounds),
            child: Text(
              _l10n.newsfeedTitle,
              style: const TextStyle(
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

  Widget _buildFeed(bool isManager, bool isOwner, String userId) {
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
              _postLimit = _pageSize;
              _hasMorePosts = true;
              _initStream();
            });
          });
        }

        final allPosts = snapshot.data ?? [];

        // Update pagination state
        if (snapshot.hasData) {
          _isLoadingMore = false;
          _hasMorePosts = allPosts.length >= _postLimit;
        }

        // Filter by search query
        final posts = _searchQuery.isEmpty
            ? allPosts
            : allPosts.where((post) {
                final title = post.title.toLowerCase();
                final content = post.content.toLowerCase();
                final author = post.authorName.toLowerCase();
                return title.contains(_searchQuery) ||
                    content.contains(_searchQuery) ||
                    author.contains(_searchQuery);
              }).toList();

        if (posts.isEmpty) {
          final String emptyMsg;
          if (_searchQuery.isNotEmpty) {
            emptyMsg = _l10n.noPostsMatchSearch;
          } else if (_selectedCategory != 'all') {
            emptyMsg = _l10n.noPostsInCategory;
          } else {
            emptyMsg = isManager
                ? _l10n.noPostsManagerHint
                : _l10n.noPostsWorkerHint;
          }
          return _EmptyState(isManager: isManager, message: emptyMsg);
        }

        return RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            setState(() {
              _postLimit = _pageSize;
              _hasMorePosts = true;
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
            itemCount: posts.length + (_hasMorePosts ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= posts.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  ),
                );
              }

              final post = posts[index];
              return PostCard(
                key: ValueKey(post.id),
                post: post,
                currentUserId: userId,
                isManager: isManager,
                isOwner: isOwner,
                index: index,
                onLike: () => _handleLike(post, userId),
                onReact: (key) => _handleReact(post, key, userId),
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
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
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
        icon: const Icon(PhosphorIconsRegular.notePencil, color: Colors.white),
        label: Text(
          _l10n.newPostButton,
          style: const TextStyle(
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
  final String? message;

  const _EmptyState({required this.isManager, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.article,
              size: 64,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context).noPostsYet,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message ??
                  (isManager
                      ? AppLocalizations.of(context).noPostsManagerHint
                      : AppLocalizations.of(context).noPostsWorkerHint),
              style: TextStyle(
                fontSize: 14,
                color: AppColors.greyMedium.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
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
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.cloudSlash,
              size: 56,
              color: Colors.red.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).loadPostsError,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).checkConnectionHint,
            style: const TextStyle(color: AppColors.greyMedium),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
              label: Text(AppLocalizations.of(context).retryButton),
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
