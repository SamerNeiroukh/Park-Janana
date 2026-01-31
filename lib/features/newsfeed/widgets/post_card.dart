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
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'עכשיו';
    } else if (difference.inMinutes < 60) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inHours < 24) {
      return 'לפני ${difference.inHours} שעות';
    } else if (difference.inDays < 7) {
      return 'לפני ${difference.inDays} ימים';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Color _getCategoryColor() {
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

  IconData _getCategoryIcon() {
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity( 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pinned indicator
            if (post.isPinned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondaryYellow.withOpacity( 0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'פוסט נעוץ',
                      style: TextStyle(
                        color: AppColors.deepOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
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
                  // Author row
                  Row(
                    children: [
                      // More options menu (for managers)
                      if (isManager || post.authorId == currentUserId)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: AppColors.greyMedium),
                          onSelected: (value) {
                            if (value == 'delete') {
                              onDelete?.call();
                            } else if (value == 'pin') {
                              onPin?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            if (isManager)
                              PopupMenuItem(
                                value: 'pin',
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(post.isPinned ? 'בטל נעיצה' : 'נעץ פוסט'),
                                    const SizedBox(width: 8),
                                    Icon(
                                      post.isPinned
                                          ? Icons.push_pin_outlined
                                          : Icons.push_pin,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    'מחק פוסט',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.delete, size: 20, color: Colors.red),
                                ],
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      // Author info
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Category badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor().withOpacity( 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        post.categoryDisplayName,
                                        style: TextStyle(
                                          color: _getCategoryColor(),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _getCategoryIcon(),
                                        size: 12,
                                        color: _getCategoryColor(),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  post.authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTimestamp(post.createdAt),
                              style: TextStyle(
                                color: AppColors.greyMedium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Author avatar
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primaryBlue.withOpacity( 0.2),
                        backgroundImage: post.authorProfilePicture.isNotEmpty
                            ? CachedNetworkImageProvider(post.authorProfilePicture)
                            : null,
                        child: post.authorProfilePicture.isEmpty
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Post title
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

                  // Post content
                  Text(
                    post.content,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Post image (if exists)
                  if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: AppColors.greyLight,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 200,
                          color: AppColors.greyLight,
                          child: const Icon(Icons.error),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Divider
                  Divider(color: AppColors.greyLight, height: 1),

                  const SizedBox(height: 12),

                  // Actions row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Comments count
                      _ActionButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: '${post.commentsCount}',
                        onTap: onComment,
                      ),

                      // Like button
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
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color ?? AppColors.greyDark,
                fontWeight: FontWeight.w500,
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
