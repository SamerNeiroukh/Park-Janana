import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import '../models/post_model.dart';
import '../services/newsfeed_service.dart';

class CommentsSheet extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final String currentUserName;
  final String currentUserProfilePicture;
  final bool isManager;

  const CommentsSheet({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserProfilePicture,
    this.isManager = false,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final NewsfeedService _newsfeedService = NewsfeedService();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _animController;
  late Stream<PostModel?> _postStream;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();

    // Create a stream to listen for real-time updates
    _postStream = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.post.id)
        .snapshots()
        .map((doc) => doc.exists ? PostModel.fromFirestore(doc) : null);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק׳';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שעות';
    if (diff.inDays < 7) return 'לפני ${diff.inDays} ימים';
    return '${date.day}/${date.month}/${date.year}';
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

      if (!mounted) return;
      _showSuccessSnackbar('התגובה נוספה');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('שגיאה בהוספת תגובה');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _deleteComment(PostComment comment) async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('מחיקת תגובה', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
              ),
            ],
          ),
          content: const Text('האם אתה בטוח שברצונך למחוק את התגובה?'),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('מחק'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _newsfeedService.deleteComment(widget.post.id, comment);
      if (!mounted) return;
      _showSuccessSnackbar('התגובה נמחקה');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('שגיאה במחיקת תגובה');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(message, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animController,
            curve: Curves.easeOutCubic,
          )),
          child: child,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.98),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: StreamBuilder<PostModel?>(
            stream: _postStream,
            initialData: widget.post,
            builder: (context, snapshot) {
              final post = snapshot.data ?? widget.post;

              return Column(
                children: [
                  _buildHandle(),
                  _buildHeader(post),
                  const Divider(height: 1),
                  Expanded(child: _buildCommentsList(post)),
                  _buildInputBar(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 48,
      height: 5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.greyMedium.withOpacity(0.3),
            AppColors.greyMedium.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildHeader(PostModel post) {
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
                      AppColors.primaryBlue.withOpacity(0.15),
                      AppColors.primaryBlue.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'תגובות',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${post.commentsCount} תגובות',
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

  Widget _buildCommentsList(PostModel post) {
    if (post.comments.isEmpty) {
      return const _EmptyComments();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: post.comments.length,
      itemBuilder: (context, index) {
        final comment = post.comments[index];
        final canDelete = comment.userId == widget.currentUserId || widget.isManager;

        return _CommentCard(
          key: ValueKey(comment.id),
          comment: comment,
          canDelete: canDelete,
          onDelete: () => _deleteComment(comment),
          timestamp: _formatTimestamp(comment.createdAt),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.greyLight.withOpacity(0.5),
                  ),
                ),
                child: TextField(
                  controller: _commentController,
                  focusNode: _focusNode,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: null,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'כתוב תגובה...',
                    hintStyle: TextStyle(
                      color: AppColors.greyMedium.withOpacity(0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
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
      ),
    );
  }
}

// ===============================
// Sub Widgets
// ===============================

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppColors.primaryBlue.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'אין תגובות עדיין',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'היה הראשון להגיב!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.greyMedium.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  final PostComment comment;
  final bool canDelete;
  final VoidCallback onDelete;
  final String timestamp;

  const _CommentCard({
    super.key,
    required this.comment,
    required this.canDelete,
    required this.onDelete,
    required this.timestamp,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  String? _resolvedProfileUrl;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _resolveProfilePicture();
  }

  Future<void> _resolveProfilePicture() async {
    final picUrl = widget.comment.userProfilePicture;

    if (picUrl.isEmpty) {
      setState(() => _isLoadingImage = false);
      return;
    }

    // If it's already a full URL (starts with http), use it directly
    if (picUrl.startsWith('http')) {
      setState(() {
        _resolvedProfileUrl = picUrl;
        _isLoadingImage = false;
      });
      return;
    }

    // If it's a Firebase Storage path, get the download URL
    try {
      final ref = FirebaseStorage.instance.ref(picUrl);
      final url = await ref.getDownloadURL();
      if (mounted) {
        setState(() {
          _resolvedProfileUrl = url;
          _isLoadingImage = false;
        });
      }
    } catch (e) {
      debugPrint('Error resolving profile picture: $e');
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.greyLight.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              _buildAvatar(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        widget.timestamp,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.greyMedium.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppColors.greyMedium.withOpacity(0.6),
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              if (widget.canDelete)
                Material(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: widget.onDelete,
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.comment.content,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.2),
            AppColors.primaryBlue.withOpacity(0.1),
          ],
        ),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.transparent,
        backgroundImage: _resolvedProfileUrl != null
            ? CachedNetworkImageProvider(_resolvedProfileUrl!)
            : null,
        child: _isLoadingImage
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

  const _SendButton({
    required this.isSubmitting,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.deepBlue],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSubmitting ? null : onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
