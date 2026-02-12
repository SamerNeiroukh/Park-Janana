import 'package:cached_network_image/cached_network_image.dart';

/// Utility for profile image cache management.
///
/// Call [evict] after uploading a new profile picture to clear
/// the old cached image so the new one loads immediately.
class ProfileImageProvider {
  ProfileImageProvider._();

  /// Evict a specific URL from the CachedNetworkImage disk + memory cache.
  static Future<void> evict(String url) async {
    if (url.isNotEmpty && url.startsWith('http')) {
      await CachedNetworkImage.evictFromCache(url);
    }
  }
}
