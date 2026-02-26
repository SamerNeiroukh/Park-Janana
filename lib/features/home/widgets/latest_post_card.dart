import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:park_janana/core/widgets/profile_avatar.dart';
import 'package:park_janana/features/newsfeed/models/post_model.dart';
import 'package:park_janana/features/newsfeed/services/newsfeed_service.dart';

/// Shows a preview of the latest newsfeed post.
///
/// Includes section label, author info, title, excerpt, optional
/// image thumbnail, and engagement counts.  Tapping navigates
/// to the full newsfeed via [onTap].
class LatestPostCard extends StatelessWidget {
  final VoidCallback onTap;

  const LatestPostCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PostModel>>(
      stream: NewsfeedService().getPostsStream(limit: 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return _PostPreview(post: snapshot.data!.first, onTap: onTap);
      },
    );
  }
}

// ── Post preview widget ────────────────────────────────────────────────────

class _PostPreview extends StatefulWidget {
  final PostModel post;
  final VoidCallback onTap;

  const _PostPreview({required this.post, required this.onTap});

  @override
  State<_PostPreview> createState() => _PostPreviewState();
}

class _PostPreviewState extends State<_PostPreview> {
  bool _pressed = false;

  String _timeAgo(Timestamp ts) {
    final diff = DateTime.now().difference(ts.toDate());
    if (diff.inMinutes < 1) return 'עכשיו';
    if (diff.inMinutes < 60) return 'לפני ${diff.inMinutes} דק\'';
    if (diff.inHours < 24) return 'לפני ${diff.inHours} שע\'';
    if (diff.inDays == 1) return 'אתמול';
    return 'לפני ${diff.inDays} ימים';
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'announcement':
        return const Color(0xFFEF4444);
      case 'event':
        return const Color(0xFF22C55E);
      case 'update':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final thumbUrl = post.allMedia.isNotEmpty ? post.allMedia.first.url : null;
    final catColor = _categoryColor(post.category);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ────────────────────────────────────
          Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10, right: 4),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'עדכון אחרון',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Card ─────────────────────────────────────────────
          GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
            onTapCancel: () => setState(() => _pressed = false),
            child: AnimatedScale(
              scale: _pressed ? 0.98 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Optional thumbnail ──────────────────
                    if (thumbUrl != null && thumbUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(22)),
                        child: Image.network(
                          thumbUrl,
                          height: 145,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),

                    // ── Text content ────────────────────────
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author row
                            Row(
                              children: [
                                ProfileAvatar(
                                  imageUrl: post.authorProfilePicture,
                                  radius: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF111827),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        _timeAgo(post.createdAt),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Category chip
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.10),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                    border: Border.all(
                                        color: catColor.withOpacity(0.25)),
                                  ),
                                  child: Text(
                                    post.categoryDisplayName,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: catColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Title
                            if (post.title.isNotEmpty)
                              Text(
                                post.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                  height: 1.35,
                                ),
                              ),

                            if (post.title.isNotEmpty &&
                                post.content.isNotEmpty)
                              const SizedBox(height: 5),

                            // Excerpt
                            if (post.content.isNotEmpty)
                              Text(
                                post.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                  height: 1.45,
                                ),
                              ),

                            const SizedBox(height: 12),

                            // Engagement row
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 14,
                                  color: const Color(0xFFEF4444)
                                      .withOpacity(0.80),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.likesCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.80),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.commentsCount}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                // "Read more" arrow
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'קרא עוד',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4F46E5)
                                            .withOpacity(0.85),
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: const Color(0xFF4F46E5)
                                          .withOpacity(0.85),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 420.ms, delay: 80.ms, curve: Curves.easeOut)
        .slideY(
            begin: 0.05,
            end: 0,
            duration: 420.ms,
            delay: 80.ms,
            curve: Curves.easeOut);
  }
}
