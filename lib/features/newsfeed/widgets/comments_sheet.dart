import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animController.forward();
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
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1),
              Expanded(child: _buildCommentsList()),
              _buildInputBar(),
            ],
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 20, 14),
      child: Row(
        children: [
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
          const Spacer(),
          Row(
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'תגובות',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${widget.post.commentsCount} תגובות',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyMedium.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList() {
    if (widget.post.comments.isEmpty) {
      return _EmptyComments();
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: widget.post.comments.length,
      itemBuilder: (context, index) {
        final comment = widget.post.comments[index];
        final canDelete = comment.userId == widget.currentUserId || widget.isManager;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + (index * 50)),
          curve: Curves.easeOut,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(20 * (1 - value), 0),
              child: child,
            ),
          ),
          child: _CommentCard(
            comment: comment,
            canDelete: canDelete,
            onDelete: () => _deleteComment(comment),
            timestamp: _formatTimestamp(comment.createdAt),
          ),
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
          children: [
            _SendButton(
              isSubmitting: _isSubmitting,
              onTap: _submitComment,
            ),
            const SizedBox(width: 12),
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

class _CommentCard extends StatelessWidget {
  final PostComment comment;
  final bool canDelete;
  final VoidCallback onDelete;
  final String timestamp;

  const _CommentCard({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF1F5F9),
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
            children: [
              if (canDelete)
                Material(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: onDelete,
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
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 11,
                        color: AppColors.greyMedium.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.greyMedium.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Container(
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
                  backgroundImage: comment.userProfilePicture.isNotEmpty
                      ? CachedNetworkImageProvider(comment.userProfilePicture)
                      : null,
                  child: comment.userProfilePicture.isEmpty
                      ? Text(
                          comment.userName.isNotEmpty
                              ? comment.userName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment.content,
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
