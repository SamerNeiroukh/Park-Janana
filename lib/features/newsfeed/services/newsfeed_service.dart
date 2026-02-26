import 'dart:io';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:park_janana/core/constants/app_constants.dart';
import '../models/post_model.dart';

class NewsfeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = AppConstants.postsCollection;

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_collectionName);

  // ===============================
  // Streams
  // ===============================

  Stream<List<PostModel>> getPostsStream({int? limit}) {
    Query<Map<String, dynamic>> query = _postsRef
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map(_mapSnapshotToPosts);
  }

  Stream<List<PostModel>> getPostsByCategory(String category, {int? limit}) {
    // No orderBy here — composite index (category + isPinned + createdAt) not
    // guaranteed to exist. We fetch the category slice and sort client-side;
    // category post counts are small enough that this is fine.
    Query<Map<String, dynamic>> query = _postsRef
        .where('category', isEqualTo: category);
    if (limit != null) query = query.limit(limit);
    return query.snapshots().map((snap) {
      final posts = _mapSnapshotToPosts(snap);
      posts.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });
      return posts;
    });
  }

  // ===============================
  // Single fetch
  // ===============================

  Future<PostModel?> getPost(String postId) async {
    final doc = await _postsRef.doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  // ===============================
  // Mutations
  // ===============================

  Future<void> createPost(PostModel post) async {
    await _postsRef.doc(post.id).set(post.toMap());
  }

  Future<void> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    await _postsRef.doc(postId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String postId) async {
    debugPrint('[DELETE] NewsfeedService.deletePost: deleting Firestore doc $postId');
    // Delete the Firestore document first so the post disappears from the UI
    // immediately. Media cleanup runs in the background and does not block.
    await _postsRef.doc(postId).delete();
    debugPrint('[DELETE] NewsfeedService.deletePost: Firestore doc deleted successfully');
    deletePostMedia(postId).catchError((Object e) {
      debugPrint('[DELETE] NewsfeedService: background media cleanup error: $e');
    });
  }

  Future<void> togglePin(String postId, bool isPinned) async {
    await _postsRef.doc(postId).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===============================
  // Likes
  // ===============================

  Future<void> likePost(String postId, String userId) async {
    await _postsRef.doc(postId).update({
      'likedBy': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> unlikePost(String postId, String userId) async {
    await _postsRef.doc(postId).update({
      'likedBy': FieldValue.arrayRemove([userId]),
    });
  }

  // ===============================
  // Comments
  // ===============================

  Future<void> addComment({
    required String postId,
    required String userId,
    required String userName,
    required String userProfilePicture,
    required String content,
  }) async {
    final comment = PostComment(
      id: const Uuid().v4(),
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      content: content,
      createdAt: Timestamp.now(),
    );

    await _postsRef.doc(postId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteComment(String postId, PostComment comment) async {
    await _postsRef.doc(postId).update({
      'comments': FieldValue.arrayRemove([comment.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===============================
  // Media Upload
  // ===============================

  Future<List<PostMedia>> uploadPostMedia({
    required String postId,
    required List<File> files,
    void Function(double progress, String status)? onProgress,
  }) async {
    final List<PostMedia> uploadedMedia = [];
    final int total = files.length;

    for (int i = 0; i < total; i++) {
      final file = files[i];
      final isVideo = _isVideoFile(file.path);
      final double fileBase = i / total;
      final double fileSlice = 1.0 / total;

      // Reports progress in [0,1] range for the whole batch
      void reportProgress(double localFraction, String status) {
        onProgress?.call(
          (fileBase + localFraction * fileSlice).clamp(0.0, 1.0),
          status,
        );
      }

      try {
        double? aspectRatio;

        if (isVideo) {
          reportProgress(0.0, 'מעלה סרטון ${i + 1}/$total...');
        } else {
          aspectRatio = await _readImageAspectRatio(file);
          reportProgress(0.0, 'מעלה תמונה ${i + 1}/$total...');
        }

        final extension = file.path.split('.').last.toLowerCase();
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
        final contentType = _getContentType(extension, isVideo);
        final ref = _storage.ref('posts/$postId/$fileName');

        // Upload with real byte-level progress via snapshotEvents
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: contentType),
        );

        await for (final snapshot in uploadTask.snapshotEvents) {
          final state = snapshot.state;
          if (state == TaskState.running || state == TaskState.paused) {
            final byteRatio = snapshot.totalBytes > 0
                ? snapshot.bytesTransferred / snapshot.totalBytes
                : 0.0;
            // Upload phase occupies 0–85% of the file's slice
            reportProgress(byteRatio * 0.85, 'מעלה ${i + 1}/$total...');
          } else if (state == TaskState.error) {
            throw Exception('Upload failed for file ${i + 1}');
          } else if (state == TaskState.success) {
            break;
          }
        }

        final url = await ref.getDownloadURL();

        // Thumbnail generation for videos (85–100% of slice)
        String? thumbnailUrl;
        if (isVideo) {
          reportProgress(0.85, 'מייצר תמונה מקדימה...');
          final result = await _generateAndUploadThumbnail(
            videoFile: file,
            postId: postId,
            index: i,
          );
          thumbnailUrl = result.url;
          aspectRatio = result.aspectRatio;
        }

        reportProgress(1.0, i + 1 == total ? 'מפרסם פוסט...' : 'קובץ ${i + 1} הועלה');

        uploadedMedia.add(PostMedia(
          url: url,
          type: isVideo ? 'video' : 'image',
          thumbnailUrl: thumbnailUrl,
          aspectRatio: aspectRatio,
        ));
      } catch (e) {
        debugPrint('Error uploading file ${i + 1}: $e');
        rethrow;
      }
    }

    return uploadedMedia;
  }

  /// Reads width/height from a local image file and returns width/height.
  Future<double?> _readImageAspectRatio(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final ratio = img.height > 0 ? img.width / img.height : null;
      img.dispose();
      codec.dispose();
      return ratio;
    } catch (e) {
      debugPrint('Failed to read image dimensions: $e');
      return null;
    }
  }

  Future<({String? url, double? aspectRatio})> _generateAndUploadThumbnail({
    required File videoFile,
    required String postId,
    required int index,
  }) async {
    try {
      debugPrint('Generating thumbnail for video...');

      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/thumb_${postId}_$index.jpg';

      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
      );

      if (thumbnail == null) {
        debugPrint('Failed to generate thumbnail');
        return (url: null, aspectRatio: null);
      }

      debugPrint('Thumbnail generated: $thumbnail');

      final thumbFile = File(thumbnail);

      // Read dimensions from thumbnail BEFORE deleting it
      double? aspectRatio;
      try {
        final bytes = await thumbFile.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final img = frame.image;
        if (img.height > 0) aspectRatio = img.width / img.height;
        img.dispose();
        codec.dispose();
      } catch (e) {
        debugPrint('Failed to read thumbnail dimensions: $e');
      }

      final thumbRef = _storage.ref('posts/$postId/thumb_$index.jpg');
      await thumbRef.putFile(
        thumbFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final thumbUrl = await thumbRef.getDownloadURL();
      debugPrint('Thumbnail uploaded: $thumbUrl');

      try { await thumbFile.delete(); } catch (_) {}

      return (url: thumbUrl, aspectRatio: aspectRatio);
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return (url: null, aspectRatio: null);
    }
  }

  String _getContentType(String extension, bool isVideo) {
    if (isVideo) {
      switch (extension) {
        case 'mp4':
          return 'video/mp4';
        case 'mov':
          return 'video/quicktime';
        case 'avi':
          return 'video/x-msvideo';
        case 'mkv':
          return 'video/x-matroska';
        case 'webm':
          return 'video/webm';
        case '3gp':
          return 'video/3gpp';
        case 'mpeg':
        case 'mpg':
          return 'video/mpeg';
        case 'm4v':
          return 'video/x-m4v';
        default:
          return 'video/mp4';
      }
    } else {
      switch (extension) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'gif':
          return 'image/gif';
        case 'webp':
          return 'image/webp';
        case 'heic':
          return 'image/heic';
        default:
          return 'image/jpeg';
      }
    }
  }

  bool _isVideoFile(String path) {
    final extension = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'mpeg', 'mpg', 'm4v'].contains(extension);
  }

  Future<void> deletePostMedia(String postId) async {
    try {
      final ref = _storage.ref('posts/$postId');
      final result = await ref.listAll();
      for (final item in result.items) {
        await item.delete();
      }
    } catch (e) {
      debugPrint('Error deleting media for post $postId: $e');
    }
  }

  // ===============================
  // Helpers
  // ===============================

  List<PostModel> _mapSnapshotToPosts(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }
}
