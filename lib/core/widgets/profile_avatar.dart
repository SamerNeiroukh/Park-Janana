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
      memCacheWidth: (radius * 4).toInt(), // 2x for retina
      memCacheHeight: (radius * 4).toInt(),
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
