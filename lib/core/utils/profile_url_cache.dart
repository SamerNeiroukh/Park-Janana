import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// In-memory cache for Firebase Storage profile picture download URLs.
/// Prevents duplicate `getDownloadURL()` network calls for the same path
/// across cards, detail sheets, and comment widgets.
class ProfileUrlCache {
  ProfileUrlCache._();

  static final Map<String, String> _cache = {};

  /// Resolves a profile picture path/URL to a usable image URL.
  /// - Full http/https URLs are returned as-is (no network call).
  /// - Firebase Storage paths are resolved once and cached indefinitely.
  /// - Empty strings return null.
  static Future<String?> resolve(String path) async {
    if (path.isEmpty) return null;
    if (path.startsWith('http')) return path;

    final cached = _cache[path];
    if (cached != null) return cached;

    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      _cache[path] = url;
      return url;
    } catch (e) {
      debugPrint('ProfileUrlCache: failed to resolve "$path": $e');
      return null;
    }
  }

  /// Clears the cache. Call on user logout.
  static void clear() => _cache.clear();
}
