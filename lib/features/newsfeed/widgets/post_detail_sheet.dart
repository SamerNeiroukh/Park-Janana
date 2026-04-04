import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import 'package:park_janana/core/utils/profile_url_cache.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';
import 'video_player_widget.dart';
import 'package:park_janana/core/widgets/app_dialog.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';

class PostDetailSheet extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName;
  final String currentUserProfilePicture;
  final bool isManager;
  final bool isOwner;
  final VoidCallback? onLike;
  final void Function(String key)? onReact;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onShowLikers;
  final bool openComments;

  const PostDetailSheet({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserProfilePicture,
    this.isManager = false,
    this.isOwner = false,
    this.onLike,
    this.onReact,
    this.onDelete,
    this.onPin,
    this.onShowLikers,
    this.openComments = false,
  });

  @override
  State<PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<PostDetailSheet> {
  final TextEditingController _commentController = TextEditingController();
  final NewsfeedService _newsfeedService = NewsfeedService();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final PageController _mediaPageController = PageController();

  Stream<PostModel?>? _postStream;

  bool _isSubmitting = false;
  String? _resolvedProfileUrl;
  bool _isLoadingProfilePic = true;
  int _currentMediaIndex = 0;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _postStream = FirebaseFirestore.instance
        .collection(AppConstants.postsCollection)
        .doc(widget.post.id)
        .snapshots()
        .map((doc) => doc.exists ? PostModel.fromFirestore(doc) : null);

    _resolveProfilePicture();

    if (widget.openComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 350), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  Future<void> _resolveProfilePicture() async {
    final url = await ProfileUrlCache.resolve(widget.post.authorProfilePicture);
    if (mounted) {
      setState(() {
        _resolvedProfileUrl = url;
        _isLoadingProfilePic = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _mediaPageController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return _l10n.nowLabel;
    if (diff.inMinutes < 60) return _l10n.minutesAgoLabel(diff.inMinutes);
    if (diff.inHours < 24) return _l10n.hoursAgoLabel(diff.inHours);
    if (diff.inDays < 7) return _l10n.daysAgoLabel(diff.inDays);
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'announcement':
        return const Color(0xFFEF4444);
      case 'update':
        return AppColors.primaryBlue;
      case 'event':
        return const Color(0xFF10B981);
      default:
        return AppColors.greyMedium;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'announcement':
        return PhosphorIconsFill.megaphone;
      case 'update':
        return PhosphorIconsRegular.arrowsClockwise;
      case 'event':
        return PhosphorIconsRegular.calendarBlank;
      default:
        return PhosphorIconsRegular.article;
    }
  }

  void _handleLikeTap() {
    HapticFeedback.lightImpact();
    widget.onLike?.call();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      await _newsfeedService.addComment(
        postId: widget.post.id,
        userId: widget.currentUserId,
        userName: widget.currentUserName,
        userProfilePicture: widget.currentUserProfilePicture,
        content: text,
      );
      _commentController.clear();
      _focusNode.unfocus();
      if (mounted) _showSnackbar(_l10n.commentAddedSuccess, isSuccess: true);
    } catch (e) {
      if (mounted) _showSnackbar(_l10n.commentAddError, isSuccess: false);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(PostComment comment) async {
    HapticFeedback.mediumImpact();
    final confirm = await showAppDialog(
      context,
      title: _l10n.deleteCommentTitle,
      message: _l10n.deleteCommentMessage,
      confirmText: _l10n.deleteLabel,
      icon: PhosphorIconsRegular.trash,
      isDestructive: true,
    );

    if (confirm != true) return;

    try {
      await _newsfeedService.deleteComment(widget.post.id, comment);
      if (mounted) _showSnackbar(_l10n.commentDeletedSuccess, isSuccess: true);
    } catch (e) {
      if (mounted) _showSnackbar(_l10n.commentDeleteError, isSuccess: false);
    }
  }

  Future<void> _editComment(PostComment comment) async {
    HapticFeedback.lightImpact();
    final newContent = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditCommentSheet(initialText: comment.content),
    );
    if (newContent == null || newContent.isEmpty || newContent == comment.content) return;
    try {
      await _newsfeedService.editComment(widget.post.id, comment, newContent);
      if (mounted) _showSnackbar(_l10n.commentUpdatedSuccess, isSuccess: true);
    } catch (e) {
      if (mounted) _showSnackbar(_l10n.commentUpdateError, isSuccess: false);
    }
  }

  void _showSnackbar(String message, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Icon(
              isSuccess ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.warningCircle,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
        backgroundColor:
            isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.93,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: StreamBuilder<PostModel?>(
          stream: _postStream,
          initialData: widget.post,
          builder: (context, snapshot) {
            final post = snapshot.data ?? widget.post;
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: _buildPostSection(post)),
                      SliverToBoxAdapter(
                          child: _buildCommentsSectionHeader(post)),
                      _buildCommentsList(post),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
                _buildCommentInput(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryBlue.withValues(alpha: 0.1),
                      AppColors.primaryBlue.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  PhosphorIconsRegular.article,
                  color: AppColors.primaryBlue,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _l10n.postDetailTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              _CloseButton(onTap: () => Navigator.pop(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostSection(PostModel post) {
    final categoryColor = _getCategoryColor(post.category);
    final isLiked = post.isLikedBy(widget.currentUserId);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (post.isPinned) _buildPinnedBadge(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAuthorRow(post, categoryColor),
                const SizedBox(height: 20),
                _buildTitle(post.title),
                const SizedBox(height: 14),
                _buildContent(post.content),
                if (post.hasMedia) _buildMediaGallery(post),
                const SizedBox(height: 20),
                _buildEngagementBar(post, isLiked),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFBBF24).withValues(alpha: 0.2),
            const Color(0xFFF59E0B).withValues(alpha: 0.1),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsFill.pushPin,
                    size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 6),
                Text(
                  _l10n.pinnedPostLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(PostModel post, Color categoryColor) {
    return Row(
      children: [
        _buildAuthorAvatar(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _CategoryChip(
                    label: post.categoryDisplayName(_l10n),
                    color: categoryColor,
                    icon: _getCategoryIcon(post.category),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    PhosphorIconsRegular.clock,
                    size: 13,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(post.createdAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (post.authorId == widget.currentUserId || widget.isOwner)
          _buildOptionsButton(post),
      ],
    );
  }

  Widget _buildAuthorAvatar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.3),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: CircleAvatar(
        radius: 26,
        backgroundColor: Colors.white,
        backgroundImage: _resolvedProfileUrl != null
            ? CachedNetworkImageProvider(_resolvedProfileUrl!)
            : null,
        child: _isLoadingProfilePic
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                ),
              )
            : (_resolvedProfileUrl == null
                ? Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null),
      ),
    );
  }

  Widget _buildOptionsButton(PostModel post) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(PhosphorIconsRegular.dotsThree,
            color: Colors.grey.shade600, size: 20),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      onSelected: (value) {
        HapticFeedback.selectionClick();
        if (value == 'delete') {
          final navigator = Navigator.of(context);
          showAppDialog(
            context,
            title: _l10n.deletePostTitle,
            message: _l10n.deletePostMessage,
            confirmText: _l10n.deleteLabel,
            icon: PhosphorIconsRegular.trash,
            isDestructive: true,
          ).then((confirmed) {
            if (!(confirmed ?? false)) return;
            navigator.pop(); // close the sheet
            widget.onDelete?.call();
          });
        }
        if (value == 'pin') widget.onPin?.call();
        if (value == 'edit') _editPost(post);
      },
      itemBuilder: (_) => [
        if (widget.isManager)
          PopupMenuItem(
            value: 'pin',
            child: Row(
              children: [
                Icon(
                  post.isPinned
                      ? PhosphorIconsRegular.pushPin
                      : PhosphorIconsFill.pushPin,
                  size: 18,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Text(post.isPinned ? _l10n.unpinPostAction : _l10n.pinPostAction),
              ],
            ),
          ),
        if (post.authorId == widget.currentUserId || widget.isManager)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.pencilSimple, size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: 12),
                Text(_l10n.editPostAction),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(PhosphorIconsRegular.trash,
                  size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 12),
              Text(_l10n.deletePostAction, style: const TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editPost(PostModel post) async {
    final titleCtrl = TextEditingController(text: post.title);
    final contentCtrl = TextEditingController(text: post.content);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(_l10n.editPostTitle,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: _l10n.postTitleLabel,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contentCtrl,
                  maxLines: 5,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: _l10n.postContentLabel,
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text(_l10n.cancelButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue),
                        child: Text(_l10n.saveButton,
                            style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    contentCtrl.dispose();
    if (saved != true) return;
    try {
      await _newsfeedService.updatePost(post.id, {
        'title': titleCtrl.text.trim(),
        'content': contentCtrl.text.trim(),
      });
      if (mounted) _showSnackbar(_l10n.postUpdatedSuccess, isSuccess: true);
    } catch (e) {
      if (mounted) _showSnackbar(_l10n.postUpdateError, isSuccess: false);
    }
  }

  Widget _buildTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildContent(String content) {
    return Text(
      content,
      style: TextStyle(
        fontSize: 15,
        height: 1.8,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildMediaGallery(PostModel post) {
    final allMedia = post.allMedia;
    if (allMedia.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          // Media PageView — height derived from current page's aspect ratio
          LayoutBuilder(
            builder: (context, constraints) {
              final currentMedia = allMedia[_currentMediaIndex];
              final ar = currentMedia.aspectRatio;
              double height;
              if (ar != null && ar > 0) {
                height = constraints.maxWidth / ar;
                height = height.clamp(160.0, 400.0);
              } else {
                height = 280;
              }
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                height: height,
                child: PageView.builder(
                  controller: _mediaPageController,
                  itemCount: allMedia.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentMediaIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final media = allMedia[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _openFullScreenMedia(allMedia, index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: media.isVideo
                              ? _buildVideoThumbnail(media)
                              : _buildImage(media),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Page indicator dots (if more than 1 item)
          if (allMedia.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  allMedia.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: index == _currentMediaIndex ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: index == _currentMediaIndex
                          ? AppColors.primaryBlue
                          : AppColors.greyLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openFullScreenMedia(List<PostMedia> allMedia, int initialIndex) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenMediaViewer(
            mediaList: allMedia,
            initialIndex: initialIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildVideoThumbnail(PostMedia media) {
    return Container(
      color: AppColors.greyDark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (media.thumbnailUrl != null)
            CachedNetworkImage(
              imageUrl: media.thumbnailUrl!,
              fit: BoxFit.contain,
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    PhosphorIconsRegular.videoCamera,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _l10n.tapToWatchVideo,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          // Play button overlay
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                PhosphorIconsRegular.play,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(PostMedia media) {
    return Container(
      color: Colors.grey.shade100,
      child: CachedNetworkImage(
        imageUrl: media.url,
        fit: BoxFit.contain,
        placeholder: (_, _) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: Colors.grey.shade200,
          child: Icon(PhosphorIconsRegular.imageBroken,
              color: Colors.grey.shade400, size: 48),
        ),
      ),
    );
  }

  Widget _buildEngagementBar(PostModel post, bool isLiked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _MergedDetailReactionButton(
              post: post,
              currentUserId: widget.currentUserId,
              onLike: _handleLikeTap,
              onReact: (key) {
                HapticFeedback.lightImpact();
                widget.onReact?.call(key);
              },
              onShowLikers: widget.onShowLikers,
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: _EngagementButton(
              icon: PhosphorIconsRegular.chatCircle,
              label: '${post.commentsCount}',
              color: Colors.grey.shade600,
              onTap: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSectionHeader(PostModel post) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              PhosphorIconsRegular.chats,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _l10n.commentsTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${post.commentsCount}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(PostModel post) {
    if (post.comments.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyComments());
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final comment = post.comments[index];
            final canDelete = comment.userId == widget.currentUserId || widget.isOwner;
            final canEdit = comment.userId == widget.currentUserId;
            return _ModernCommentCard(
              comment: comment,
              canDelete: canDelete,
              canEdit: canEdit,
              onDelete: () => _deleteComment(comment),
              onEdit: () => _editComment(comment),
              timestamp: _formatTimestamp(comment.createdAt),
            );
          },
          childCount: post.comments.length,
        ),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              PhosphorIconsRegular.chatCircle,
              size: 40,
              color: AppColors.primaryBlue.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _l10n.noCommentsEmpty,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _l10n.beFirstToCommentOnPost,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                maxLines: null,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: _l10n.addCommentHint,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _SendButton(
            isSubmitting: _isSubmitting,
            onTap: _submitComment,
          ),
        ],
      ),
    );
  }
}

// ===============================
// Sub Widgets
// ===============================

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(PhosphorIconsRegular.x, size: 22, color: Colors.grey.shade600),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CategoryChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _EngagementButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single merged reaction button: tap = ❤️ like, long-press = emoji picker ─
class _MergedDetailReactionButton extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final VoidCallback? onLike;
  final void Function(String key)? onReact;
  final VoidCallback? onShowLikers;

  const _MergedDetailReactionButton({
    required this.post,
    required this.currentUserId,
    this.onLike,
    this.onReact,
    this.onShowLikers,
  });

  @override
  State<_MergedDetailReactionButton> createState() =>
      _MergedDetailReactionButtonState();
}

class _MergedDetailReactionButtonState
    extends State<_MergedDetailReactionButton> {
  OverlayEntry? _overlay;
  final GlobalKey _key = GlobalKey();

  bool get _isLiked => widget.post.isLikedBy(widget.currentUserId);
  bool get _hasThumbsReaction =>
      widget.post.hasReacted('thumbs', widget.currentUserId);
  bool get _hasPartyReaction =>
      widget.post.hasReacted('party', widget.currentUserId);
  bool get _hasAnyReaction =>
      _isLiked || _hasThumbsReaction || _hasPartyReaction;
  int get _totalCount =>
      widget.post.likesCount +
      widget.post.reactionCount('thumbs') +
      widget.post.reactionCount('party');

  String get _displayEmoji {
    if (_hasPartyReaction) return '🎉';
    if (_hasThumbsReaction) return '👍';
    return '❤️';
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  void _showPicker() {
    HapticFeedback.mediumImpact();
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.of(context).size.width;
    const pickerWidth = 160.0;
    final left = (pos.dx + size.width / 2 - pickerWidth / 2)
        .clamp(8.0, screenWidth - pickerWidth - 8);

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
            ),
          ),
          Positioned(
            left: left,
            top: pos.dy - 64,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: pickerWidth,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _DetailPickerEmoji(
                      emoji: '❤️',
                      isActive: _isLiked,
                      onTap: () {
                        _removeOverlay();
                        widget.onLike?.call();
                      },
                    ),
                    _DetailPickerEmoji(
                      emoji: '👍',
                      isActive: _hasThumbsReaction,
                      onTap: () {
                        _removeOverlay();
                        widget.onReact?.call('thumbs');
                      },
                    ),
                    _DetailPickerEmoji(
                      emoji: '🎉',
                      isActive: _hasPartyReaction,
                      onTap: () {
                        _removeOverlay();
                        widget.onReact?.call('party');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: _key,
        onTap: () {
          HapticFeedback.lightImpact();
          if (_hasThumbsReaction) {
            widget.onReact?.call('thumbs');
          } else if (_hasPartyReaction) {
            widget.onReact?.call('party');
          } else {
            widget.onLike?.call();
          }
        },
        onLongPress: _showPicker,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: _hasAnyReaction ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.elasticOut,
                child: Text(_displayEmoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 8),
              Text(
                '$_totalCount',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _hasAnyReaction
                      ? AppColors.primaryBlue
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPickerEmoji extends StatelessWidget {
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _DetailPickerEmoji({
    required this.emoji,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: isActive ? 26 : 22),
        ),
      ),
    );
  }
}

class _ModernCommentCard extends StatefulWidget {
  final PostComment comment;
  final bool canDelete;
  final bool canEdit;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final String timestamp;

  const _ModernCommentCard({
    required this.comment,
    required this.canDelete,
    required this.canEdit,
    required this.onDelete,
    required this.onEdit,
    required this.timestamp,
  });

  @override
  State<_ModernCommentCard> createState() => _ModernCommentCardState();
}

class _ModernCommentCardState extends State<_ModernCommentCard> {
  String? _resolvedProfileUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _resolveProfilePicture();
  }

  Future<void> _resolveProfilePicture() async {
    final url = await ProfileUrlCache.resolve(widget.comment.userProfilePicture);
    if (mounted) {
      setState(() {
        _resolvedProfileUrl = url;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(PhosphorIconsRegular.clock,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          widget.timestamp,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.canEdit)
                GestureDetector(
                  onTap: widget.onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(left: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.pencilSimple,
                      size: 16,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              if (widget.canDelete)
                GestureDetector(
                  onTap: widget.onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.trash,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              widget.comment.content,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withValues(alpha: 0.3),
            AppColors.primaryBlue.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        backgroundImage: _resolvedProfileUrl != null
            ? CachedNetworkImageProvider(_resolvedProfileUrl!)
            : null,
        child: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue.withValues(alpha: 0.5),
                ),
              )
            : (_resolvedProfileUrl == null
                ? Text(
                    widget.comment.userName.isNotEmpty
                        ? widget.comment.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  )
                : null),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isSubmitting;
  final VoidCallback onTap;

  const _SendButton({required this.isSubmitting, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSubmitting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primaryBlue, AppColors.deepBlue],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(PhosphorIconsRegular.paperPlaneTilt, color: Colors.white, size: 22),
      ),
    );
  }
}


class _FullScreenMediaViewer extends StatefulWidget {
  final List<PostMedia> mediaList;
  final int initialIndex;

  const _FullScreenMediaViewer({
    required this.mediaList,
    required this.initialIndex,
  });

  @override
  State<_FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<_FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Media PageView
            PageView.builder(
              controller: _pageController,
              itemCount: widget.mediaList.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final media = widget.mediaList[index];
                return Center(
                  child: media.isVideo
                      ? VideoPlayerWidget(
                          videoUrl: media.url,
                          autoPlay: true,
                          showControls: true,
                          expectedAspectRatio: media.aspectRatio,
                        )
                      : InteractiveViewer(
                          minScale: 0.5,
                          maxScale: 4.0,
                          child: CachedNetworkImage(
                            imageUrl: media.url,
                            fit: BoxFit.contain,
                            placeholder: (_, _) => const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (_, _, _) => const Icon(
                              PhosphorIconsRegular.imageBroken,
                              color: Colors.white54,
                              size: 64,
                            ),
                          ),
                        ),
                );
              },
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    PhosphorIconsRegular.x,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Page indicator
            if (widget.mediaList.length > 1)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / ${widget.mediaList.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Comment Sheet ────────────────────────────────────────────────────

class _EditCommentSheet extends StatefulWidget {
  final String initialText;
  const _EditCommentSheet({required this.initialText});

  @override
  State<_EditCommentSheet> createState() => _EditCommentSheetState();
}

class _EditCommentSheetState extends State<_EditCommentSheet> {
  late final TextEditingController _ctrl;
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _l10n.editCommentTitle,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ctrl,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: _l10n.editCommentHint,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(_l10n.cancelButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue),
                      child: Text(
                        _l10n.saveButton,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
