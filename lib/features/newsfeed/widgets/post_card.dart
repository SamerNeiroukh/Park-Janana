import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import '../models/post_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final bool isManager;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onTap;
  final VoidCallback? onShowLikers;
  final int index;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    this.isManager = false,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.onPin,
    this.onTap,
    this.onShowLikers,
    this.index = 0,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLikeAnimating = false;

  // Profile picture resolution
  String? _resolvedProfileUrl;
  bool _isLoadingProfilePic = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _resolveProfilePicture();
  }

  Future<void> _resolveProfilePicture() async {
    final picUrl = widget.post.authorProfilePicture;

    if (picUrl.isEmpty) {
      setState(() => _isLoadingProfilePic = false);
      return;
    }

    // If it's already a full URL, use it directly
    if (picUrl.startsWith('http')) {
      setState(() {
        _resolvedProfileUrl = picUrl;
        _isLoadingProfilePic = false;
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
          _isLoadingProfilePic = false;
        });
      }
    } catch (e) {
      debugPrint('Error resolving author profile picture: $e');
      if (mounted) {
        setState(() => _isLoadingProfilePic = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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

  Color _categoryColor() {
    switch (widget.post.category) {
      case 'announcement':
        return AppColors.salmon;
      case 'update':
        return AppColors.primaryBlue;
      case 'event':
        return AppColors.success;
      default:
        return AppColors.greyMedium;
    }
  }

  IconData _categoryIcon() {
    switch (widget.post.category) {
      case 'announcement':
        return Icons.campaign_rounded;
      case 'update':
        return Icons.update_rounded;
      case 'event':
        return Icons.event_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  void _handleLikeTap() {
    HapticFeedback.lightImpact();
    setState(() => _isLikeAnimating = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isLikeAnimating = false);
    });
    widget.onLike?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.post.isLikedBy(widget.currentUserId);
    final categoryColor = _categoryColor();

    // Card without full-tap interaction - only buttons are interactive
    return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Colors.white.withOpacity(0.85),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ===== PINNED STRIP =====
                    if (widget.post.isPinned) _buildPinnedStrip(),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ===== HEADER =====
                          _buildHeader(categoryColor),

                          const SizedBox(height: 16),

                          // ===== TITLE =====
                          Text(
                            widget.post.title,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ===== CONTENT (tappable) =====
                          GestureDetector(
                            onTap: widget.onTap,
                            behavior: HitTestBehavior.opaque,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    // Check if text will be truncated
                                    final textSpan = TextSpan(
                                      text: widget.post.content,
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.6,
                                        color: AppColors.textSecondary.withOpacity(0.9),
                                      ),
                                    );
                                    final textPainter = TextPainter(
                                      text: textSpan,
                                      maxLines: 4,
                                      textDirection: TextDirection.rtl,
                                    );
                                    textPainter.layout(maxWidth: constraints.maxWidth);
                                    final isOverflowing = textPainter.didExceedMaxLines;

                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          widget.post.content,
                                          textAlign: TextAlign.right,
                                          maxLines: 4,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: AppColors.textSecondary.withOpacity(0.9),
                                          ),
                                        ),
                                        if (isOverflowing)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                Icon(
                                                  Icons.arrow_back_ios_rounded,
                                                  size: 12,
                                                  color: AppColors.primaryBlue,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'קרא עוד',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.primaryBlue,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // ===== IMAGE =====
                          if (widget.post.imageUrl != null &&
                              widget.post.imageUrl!.isNotEmpty)
                            _buildImage(),

                          const SizedBox(height: 16),

                          // ===== ACTIONS =====
                          _buildActions(isLiked),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildPinnedStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondaryYellow.withOpacity(0.3),
            AppColors.deepOrange.withOpacity(0.15),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.deepOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: const [
                Icon(
                  Icons.push_pin_rounded,
                  size: 14,
                  color: AppColors.deepOrange,
                ),
                SizedBox(width: 4),
                Text(
                  'פוסט נעוץ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color categoryColor) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        _buildAvatar(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  widget.post.authorName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                _CategoryBadge(
                  label: widget.post.categoryDisplayName,
                  color: categoryColor,
                  icon: _categoryIcon(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  _formatTimestamp(widget.post.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.greyMedium.withOpacity(0.8),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: AppColors.greyMedium.withOpacity(0.7),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        if (widget.isManager || widget.post.authorId == widget.currentUserId)
          _buildOptionsMenu(),
      ],
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
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.transparent,
        backgroundImage: _resolvedProfileUrl != null
            ? CachedNetworkImageProvider(_resolvedProfileUrl!)
            : null,
        child: _isLoadingProfilePic
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue.withOpacity(0.5),
                ),
              )
            : (_resolvedProfileUrl == null
                ? Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  )
                : null),
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_horiz_rounded,
          color: AppColors.greyMedium,
          size: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        onSelected: (value) {
          HapticFeedback.selectionClick();
          if (value == 'delete') widget.onDelete?.call();
          if (value == 'pin') widget.onPin?.call();
        },
        itemBuilder: (_) => [
          if (widget.isManager)
            PopupMenuItem(
              value: 'pin',
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    widget.post.isPinned
                        ? Icons.push_pin_outlined
                        : Icons.push_pin_rounded,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.post.isPinned ? 'בטל נעיצה' : 'נעץ פוסט',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                const Text(
                  'מחק פוסט',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: widget.post.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryBlue.withOpacity(0.5),
                ),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.greyLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.greyMedium,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(bool isLiked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LikeButton(
            isLiked: isLiked,
            count: widget.post.likesCount,
            isAnimating: _isLikeAnimating,
            onTap: _handleLikeTap,
            onShowLikers: () {
              HapticFeedback.selectionClick();
              widget.onShowLikers?.call();
            },
          ),
          Container(
            width: 1,
            height: 24,
            color: AppColors.greyMedium.withOpacity(0.3),
          ),
          _ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: '${widget.post.commentsCount}',
            onTap: () {
              HapticFeedback.selectionClick();
              widget.onComment?.call();
            },
          ),
        ],
      ),
    );
  }
}

// ===============================
// Sub Widgets
// ===============================

class _CategoryBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CategoryBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              icon,
              size: 20,
              color: AppColors.greyDark.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final bool isAnimating;
  final VoidCallback? onTap;
  final VoidCallback? onShowLikers;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.isAnimating,
    this.onTap,
    this.onShowLikers,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        // Like/Unlike button (heart icon)
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AnimatedScale(
              scale: isAnimating ? 1.3 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: Icon(
                isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: isLiked ? Colors.red : AppColors.greyDark.withOpacity(0.7),
              ),
            ),
          ),
        ),
        // Likes count (tappable to show likers)
        InkWell(
          onTap: onShowLikers,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLiked ? Colors.red : AppColors.greyDark.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
