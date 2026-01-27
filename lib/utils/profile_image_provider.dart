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

  /// Returns an ImageProvider that can be used in CircleAvatar / Image widgets.
  static Future<ImageProvider> resolve({
    String? storagePath,
    String? fallbackUrl,
  }) async {
    try {
      // 1️⃣ Preferred: Firebase Storage path
      if (storagePath != null && storagePath.isNotEmpty) {
        final ref = FirebaseStorage.instance.ref(storagePath);
        final downloadUrl = await ref.getDownloadURL();
        return CachedNetworkImageProvider(downloadUrl);
      }

      // 2️⃣ Legacy fallback: static URL
      if (fallbackUrl != null &&
          fallbackUrl.isNotEmpty &&
          fallbackUrl.startsWith('http')) {
        return CachedNetworkImageProvider(fallbackUrl);
      }
    } catch (e) {
      debugPrint('ProfileImageProvider error: $e');
    }

    // 3️⃣ Final fallback
    return const AssetImage(_defaultAsset);
  }
}
