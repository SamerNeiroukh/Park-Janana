import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../models/post_model.dart';

class NewsfeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const String _collectionName = 'posts';

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_collectionName);

  // ===============================
  // Streams
  // ===============================

  Stream<List<PostModel>> getPostsStream() {
    return _postsRef
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshotToPosts);
  }

  Stream<List<PostModel>> getPostsByCategory(String category) {
    return _postsRef
        .where('category', isEqualTo: category)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshotToPosts);
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
    await deletePostMedia(postId);
    await _postsRef.doc(postId).delete();
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
    Function(int current, int total)? onProgress,
  }) async {
    final List<PostMedia> uploadedMedia = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final isVideo = _isVideoFile(file.path);
      final extension = file.path.split('.').last.toLowerCase();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
      final contentType = _getContentType(extension, isVideo);

      debugPrint('Uploading file ${i + 1}/${files.length}: $fileName (isVideo: $isVideo, contentType: $contentType)');

      final ref = _storage.ref('posts/$postId/$fileName');

      try {
        final uploadTask = ref.putFile(
          file,
          SettableMetadata(contentType: contentType),
        );

        // Wait for upload to complete
        await uploadTask;
        debugPrint('Upload complete for: $fileName');

        final url = await ref.getDownloadURL();
        debugPrint('Got download URL: $url');

        // Generate and upload thumbnail for videos
        String? thumbnailUrl;
        if (isVideo) {
          thumbnailUrl = await _generateAndUploadThumbnail(
            videoFile: file,
            postId: postId,
            index: i,
          );
        }

        uploadedMedia.add(PostMedia(
          url: url,
          type: isVideo ? 'video' : 'image',
          thumbnailUrl: thumbnailUrl,
        ));

        onProgress?.call(i + 1, files.length);
      } catch (e) {
        debugPrint('Error uploading $fileName: $e');
        rethrow;
      }
    }

    return uploadedMedia;
  }

  Future<String?> _generateAndUploadThumbnail({
    required File videoFile,
    required String postId,
    required int index,
  }) async {
    try {
      debugPrint('Generating thumbnail for video...');

      // Get temp directory to store thumbnail
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = '${tempDir.path}/thumb_${postId}_$index.jpg';

      // Generate thumbnail from video
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoFile.path,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 400,
        quality: 75,
      );

      if (thumbnail == null) {
        debugPrint('Failed to generate thumbnail');
        return null;
      }

      debugPrint('Thumbnail generated: $thumbnail');

      // Upload thumbnail to Firebase Storage
      final thumbFile = File(thumbnail);
      final thumbRef = _storage.ref('posts/$postId/thumb_$index.jpg');

      await thumbRef.putFile(
        thumbFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final thumbUrl = await thumbRef.getDownloadURL();
      debugPrint('Thumbnail uploaded: $thumbUrl');

      // Clean up temp file
      try {
        await thumbFile.delete();
      } catch (_) {}

      return thumbUrl;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
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
