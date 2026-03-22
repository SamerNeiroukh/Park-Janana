import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// A fast, synchronous avatar widget that displays profile pictures.
///
/// Uses [CachedNetworkImage] for automatic disk + memory caching.
/// Shows a shimmer placeholder while loading, default avatar on error.
/// No async calls — the download URL is passed directly from Firestore.
class ProfileAvatar extends StatelessWidget {
  /// Direct download URL (from Firestore `profile_picture` field).
  final String? imageUrl;

  final double radius;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 20,
    this.backgroundColor,
  });

  /// Opens a full-screen viewer for [imageUrl].
  /// Does nothing if [imageUrl] is null/empty/invalid.
  static void showFullScreen(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty || !imageUrl.startsWith('http')) {
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) => _FullScreenPhotoPage(imageUrl: imageUrl),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  static const String _defaultAsset = 'assets/images/default_profile.png';

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final bgColor = backgroundColor ?? Colors.grey.shade200;

    if (url == null || url.isEmpty || !url.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: const AssetImage(_defaultAsset),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: imageProvider,
      ),
      placeholder: (context, url) => _ShimmerCircle(
        radius: radius,
        backgroundColor: bgColor,
      ),
      errorWidget: (context, url, error) => CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: const AssetImage(_defaultAsset),
      ),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
      memCacheWidth: (radius * 4).toInt().clamp(0, 256),
      memCacheHeight: (radius * 4).toInt().clamp(0, 256),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  final double radius;
  final Color backgroundColor;

  const _ShimmerCircle({required this.radius, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
      ),
    );
  }
}

class _FullScreenPhotoPage extends StatelessWidget {
  final String imageUrl;
  const _FullScreenPhotoPage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, _, _) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: topPad + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
