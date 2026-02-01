import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import '../models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUserId;
  final bool isManager;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final VoidCallback? onTap;

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
  });

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
    switch (post.category) {
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
    switch (post.category) {
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

  @override
  Widget build(BuildContext context) {
    final isLiked = post.isLikedBy(currentUserId);
    final categoryColor = _categoryColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== PINNED STRIP =====
            if (post.isPinned)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryYellow.withOpacity(0.25),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Text(
                      'פוסט נעוץ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepOrange,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: AppColors.deepOrange,
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== HEADER =====
                  Row(
                    children: [
                      if (isManager || post.authorId == currentUserId)
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.greyMedium,
                          ),
                          onSelected: (value) {
                            if (value == 'delete') onDelete?.call();
                            if (value == 'pin') onPin?.call();
                          },
                          itemBuilder: (_) => [
                            if (isManager)
                              PopupMenuItem(
                                value: 'pin',
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(post.isPinned
                                        ? 'בטל נעיצה'
                                        : 'נעץ פוסט'),
                                    const SizedBox(width: 8),
                                    Icon(
                                      post.isPinned
                                          ? Icons.push_pin_outlined
                                          : Icons.push_pin_rounded,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    'מחק פוסט',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              _CategoryBadge(
                                label: post.categoryDisplayName,
                                color: categoryColor,
                                icon: _categoryIcon(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.greyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                        backgroundImage: post.authorProfilePicture.isNotEmpty
                            ? CachedNetworkImageProvider(
                                post.authorProfilePicture)
                            : null,
                        child: post.authorProfilePicture.isEmpty
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ===== TITLE =====
                  Text(
                    post.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ===== CONTENT =====
                  Text(
                    post.content,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.55,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // ===== IMAGE =====
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 200,
                          color: AppColors.greyLight,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 200,
                          color: AppColors.greyLight,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // ===== ACTIONS =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${post.commentsCount}',
                        onTap: onComment,
                      ),
                      _ActionButton(
                        icon: isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        label: '${post.likesCount}',
                        color: isLiked ? Colors.red : null,
                        onTap: onLike,
                      ),
                    ],
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

/// ===============================
/// Sub widgets
/// ===============================

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, size: 12, color: color),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: color ?? AppColors.greyDark,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              icon,
              size: 22,
              color: color ?? AppColors.greyDark,
            ),
          ],
        ),
      ),
    );
  }
}
