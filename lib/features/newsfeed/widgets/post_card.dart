import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:park_janana/core/constants/app_colors.dart';
import 'package:park_janana/core/utils/profile_url_cache.dart';
import 'package:park_janana/core/l10n/app_localizations.dart';
import '../models/post_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final bool isManager;
  final bool isOwner;
  final VoidCallback? onLike;
  final void Function(String key)? onReact;
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
    this.isOwner = false,
    this.onLike,
    this.onReact,
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

class _PostCardState extends State<PostCard> {
  // Press animation (replaces the dead AnimationController that was never used)
  bool _isPressed = false;

  // Like animation
  bool _isLikeAnimating = false;

  // Profile picture (resolved once via shared URL cache)
  String? _resolvedProfileUrl;
  bool _isLoadingProfilePic = true;

  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context);
  }

  @override
  void initState() {
    super.initState();
    _resolveProfilePicture();
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

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return _l10n.nowLabel;
    if (diff.inMinutes < 60) return _l10n.minutesAgoLabel(diff.inMinutes);
    if (diff.inHours < 24) return _l10n.hoursAgoLabel(diff.inHours);
    if (diff.inDays < 7) return _l10n.daysAgoLabel(diff.inDays);
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
    final date = widget.post.createdAt.toDate();

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.white,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: (highlighted) {
                setState(() => _isPressed = highlighted);
              },
              splashColor: categoryColor.withValues(alpha: 0.04),
              highlightColor: categoryColor.withValues(alpha: 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category accent strip (3px, always visible)
                  Container(height: 3, color: categoryColor),

                  // Pinned strip (only when pinned)
                  if (widget.post.isPinned) _buildPinnedStrip(),

                  // Main content
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(categoryColor, date),
                        const SizedBox(height: 16),

                        // Title
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

                        // Content (card InkWell handles tap — no wrapper needed)
                        _buildContent(),

                        // Media (card InkWell handles tap — no wrapper needed)
                        if (widget.post.hasMedia) _buildMediaSection(),

                        const SizedBox(height: 16),

                        // Actions (like + comment — have their own InkWell, wins gesture arena)
                        _buildActions(isLiked),
                      ],
                    ),
                  ),
                ],
              ),
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
            AppColors.secondaryYellow.withValues(alpha: 0.25),
            AppColors.deepOrange.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.deepOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                const Icon(PhosphorIconsFill.pushPin, size: 13, color: AppColors.deepOrange),
                const SizedBox(width: 4),
                Text(
                  _l10n.pinnedPostLabel,
                  style: const TextStyle(
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

  Widget _buildHeader(Color categoryColor, DateTime date) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        _buildAvatar(categoryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Flexible(
                    child: Text(
                      widget.post.authorName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CategoryBadge(
                    label: widget.post.categoryDisplayName(_l10n),
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
                    _formatTimestamp(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.greyMedium.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    PhosphorIconsRegular.clock,
                    size: 12,
                    color: AppColors.greyMedium.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.post.authorId == widget.currentUserId || widget.isOwner)
          _buildOptionsMenu(),
      ],
    );
  }

  Widget _buildAvatar(Color categoryColor) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            categoryColor.withValues(alpha: 0.25),
            categoryColor.withValues(alpha: 0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: categoryColor.withValues(alpha: 0.15),
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
                  color: categoryColor.withValues(alpha: 0.5),
                ),
              )
            : (_resolvedProfileUrl == null
                ? Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  )
                : null),
      ),
    );
  }

  Widget _buildOptionsMenu() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(
          PhosphorIconsRegular.dotsThree,
          color: AppColors.greyMedium,
          size: 20,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        onSelected: (value) {
          HapticFeedback.selectionClick();
          if (value == 'delete') {
            debugPrint('[DELETE] PostCard onSelected: delete tapped, onDelete=${widget.onDelete != null ? "set" : "null"}');
            widget.onDelete?.call();
          }
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
                        ? PhosphorIconsRegular.pushPin
                        : PhosphorIconsFill.pushPin,
                    size: 18,
                    color: AppColors.primaryBlue,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.post.isPinned ? _l10n.unpinPostAction : _l10n.pinPostAction,
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
                const Icon(PhosphorIconsRegular.trash, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                Text(
                  _l10n.deletePostAction,
                  style: const TextStyle(
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

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.post.content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
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
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
            if (isOverflowing)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _l10n.readMoreLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      PhosphorIconsRegular.caretDown,
                      size: 16,
                      color: AppColors.primaryBlue.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMediaSection() {
    final allMedia = widget.post.allMedia;
    if (allMedia.isEmpty) return const SizedBox.shrink();

    // Single media item — full width, height driven by stored aspect ratio
    if (allMedia.length == 1) {
      final media = allMedia.first;
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final ar = media.aspectRatio;
            double height;
            if (ar != null && ar > 0) {
              height = constraints.maxWidth / ar;
              // Keep cards reasonable — cap between 120 and 320px
              height = height.clamp(120.0, 320.0);
            } else {
              height = 200;
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: height,
                child: _buildMediaItem(media),
              ),
            );
          },
        ),
      );
    }

    // Multiple items — 2:1 grid with "+X more" overlay
    final remainingCount = allMedia.length - 4;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 200,
          child: Row(
            children: [
              // Left side — first image (larger)
              Expanded(
                flex: 2,
                child: _buildMediaItem(allMedia[0], height: 200),
              ),
              const SizedBox(width: 4),
              // Right side — stacked smaller images
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    Expanded(child: _buildMediaItem(allMedia[1])),
                    if (allMedia.length > 2) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            _buildMediaItem(
                              allMedia.length > 3 ? allMedia[3] : allMedia[2],
                            ),
                            if (remainingCount > 0)
                              Container(
                                color: Colors.black54,
                                child: Center(
                                  child: Text(
                                    '+$remainingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaItem(PostMedia media, {double? height}) {
    if (media.isVideo) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.greyDark,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.thumbnailUrl != null)
              CachedNetworkImage(
                imageUrl: media.thumbnailUrl!,
                fit: BoxFit.cover,
              )
            else
              const Center(
                child: Icon(PhosphorIconsRegular.videoCamera, color: Colors.white54, size: 40),
              ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.play, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: media.url,
      fit: BoxFit.cover,
      height: height,
      placeholder: (_, _) => Container(
        height: height,
        color: AppColors.greyLight.withValues(alpha: 0.5),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryBlue.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
      errorWidget: (_, _, _) => Container(
        height: height,
        color: AppColors.greyLight.withValues(alpha: 0.5),
        child: const Icon(PhosphorIconsRegular.imageBroken, color: AppColors.greyMedium, size: 40),
      ),
    );
  }

  Widget _buildActions(bool isLiked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MergedReactionButton(
            post: widget.post,
            currentUserId: widget.currentUserId,
            isAnimating: _isLikeAnimating,
            onLike: _handleLikeTap,
            onReact: (key) {
              HapticFeedback.lightImpact();
              widget.onReact?.call(key);
            },
            onShowLikers: () {
              HapticFeedback.selectionClick();
              widget.onShowLikers?.call();
            },
          ),
          Container(
              width: 1,
              height: 24,
              color: AppColors.greyMedium.withValues(alpha: 0.25)),
          _ActionButton(
            icon: PhosphorIconsRegular.chatCircle,
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
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
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

// ── Single merged reaction button: tap = ❤️ like, long-press = emoji picker ─
class _MergedReactionButton extends StatefulWidget {
  final PostModel post;
  final String currentUserId;
  final bool isAnimating;
  final VoidCallback? onLike;
  final void Function(String key)? onReact;
  final VoidCallback? onShowLikers;

  const _MergedReactionButton({
    required this.post,
    required this.currentUserId,
    this.isAnimating = false,
    this.onLike,
    this.onReact,
    this.onShowLikers,
  });

  @override
  State<_MergedReactionButton> createState() => _MergedReactionButtonState();
}

class _MergedReactionButtonState extends State<_MergedReactionButton> {
  OverlayEntry? _overlay;
  final GlobalKey _key = GlobalKey();

  bool get _isLiked => widget.post.isLikedBy(widget.currentUserId);
  bool get _hasThumbsReaction =>
      widget.post.hasReacted('thumbs', widget.currentUserId);
  bool get _hasPartyReaction =>
      widget.post.hasReacted('party', widget.currentUserId);
  bool get _hasAnyReaction => _isLiked || _hasThumbsReaction || _hasPartyReaction;
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
                    _PickerEmoji(
                      emoji: '❤️',
                      isActive: _isLiked,
                      onTap: () {
                        _removeOverlay();
                        widget.onLike?.call();
                      },
                    ),
                    _PickerEmoji(
                      emoji: '👍',
                      isActive: _hasThumbsReaction,
                      onTap: () {
                        _removeOverlay();
                        widget.onReact?.call('thumbs');
                      },
                    ),
                    _PickerEmoji(
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        InkWell(
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AnimatedScale(
              scale: widget.isAnimating ? 1.3 : (_hasAnyReaction ? 1.1 : 1.0),
              duration: const Duration(milliseconds: 150),
              child: Text(
                _displayEmoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
        ),
        InkWell(
          onTap: widget.onShowLikers,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              '$_totalCount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _hasAnyReaction
                    ? AppColors.primaryBlue
                    : AppColors.greyDark.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerEmoji extends StatelessWidget {
  final String emoji;
  final bool isActive;
  final VoidCallback onTap;

  const _PickerEmoji({
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
            Icon(icon, size: 20, color: AppColors.greyDark.withValues(alpha: 0.65)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.greyDark.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

