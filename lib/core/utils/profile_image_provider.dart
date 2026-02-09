import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A helper that resolves a profile image safely.
///
/// Priority:
/// 1. Firebase Storage path (secure, recommended)
/// 2. Fallback URL (legacy support)
/// 3. Default asset image
class ProfileImageProvider {
  static const String _defaultAsset = 'assets/images/default_profile.png';

  static const AssetImage defaultImage = AssetImage(_defaultAsset);

  /// Cache resolved Storage download URLs to avoid repeated API calls.
  static final Map<String, String> _urlCache = {};

  /// Invalidate a cached download URL so the next resolve() fetches a fresh one.
  /// Call this after uploading a new profile picture.
  static void invalidate(String storagePath) {
    _urlCache.remove(storagePath);
  }

  /// Returns an ImageProvider that can be used in CircleAvatar / Image widgets.
  static Future<ImageProvider> resolve({
    String? storagePath,
    String? fallbackUrl,
  }) async {
    // 1. Preferred: Firebase Storage path (with URL cache)
    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        final cachedUrl = _urlCache[storagePath];
        if (cachedUrl != null) {
          return CachedNetworkImageProvider(cachedUrl);
        }
        final ref = FirebaseStorage.instance.ref(storagePath);
        final downloadUrl = await ref
            .getDownloadURL()
            .timeout(const Duration(seconds: 5));
        _urlCache[storagePath] = downloadUrl;
        return CachedNetworkImageProvider(downloadUrl);
      } catch (e) {
        debugPrint('ProfileImageProvider storage error: $e');
        // Fall through to try fallbackUrl
      }
    }

    // 2. Legacy fallback: static URL
    if (fallbackUrl != null &&
        fallbackUrl.isNotEmpty &&
        fallbackUrl.startsWith('http')) {
      return CachedNetworkImageProvider(fallbackUrl);
    }

    // 3. Final fallback
    return defaultImage;
  }
}
