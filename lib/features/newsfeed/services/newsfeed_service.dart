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

  Future<void> deletePost(PostModel post) async {
    await _postsRef.doc(post.id).delete();
    // Delete Storage files in the background — does not block the UI.
    _deleteMediaFiles(post).catchError((Object e) {
      debugPrint('[DELETE] NewsfeedService: background media cleanup error: $e');
    });
  }

  Future<void> _deleteMediaFiles(PostModel post) async {
    final urls = <String>[
      for (final m in post.media) ...[
        m.url,
        if (m.thumbnailUrl != null) m.thumbnailUrl!,
      ],
      if (post.imageUrl != null && post.imageUrl!.isNotEmpty) post.imageUrl!,
    ];
    for (final url in urls) {
      try {
        await _storage.refFromURL(url).delete();
      } catch (e) {
        debugPrint('[DELETE] Failed to delete file $url: $e');
      }
    }
  }

  Future<void> togglePin(String postId, bool isPinned) async {
    await _postsRef.doc(postId).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===============================
  // Reactions (mutually exclusive)
  // ===============================

  /// Sets or clears a reaction for [userId] on [postId].
  /// A user can hold at most one active reaction per post at a time.
  ///
  /// [reactionKey] — one of: 'love' (❤️ → likedBy), 'thumbs' (👍), 'party' (🎉).
  ///
  /// Behaviour:
  ///   • If [reactionKey] is already active for the user → remove it (toggle off).
  ///   • Otherwise → remove user from every other reaction slot, add to this one.
  Future<void> setReaction(
      String postId, String userId, String reactionKey) async {
    final docRef = _postsRef.doc(postId);
    await _firestore.runTransaction((txn) async {
      final doc = await txn.get(docRef);
      final data = doc.data() ?? {};

      final likedBy = List<String>.from(data['likedBy'] as List? ?? []);
      final reactionsRaw = Map<String, dynamic>.from(
          (data['reactions'] as Map?)?.cast<String, dynamic>() ?? {});
      final thumbs = List<String>.from(reactionsRaw['thumbs'] as List? ?? []);
      final party  = List<String>.from(reactionsRaw['party']  as List? ?? []);

      // Is this the user's currently active reaction?
      final bool isActive = switch (reactionKey) {
        'love'   => likedBy.contains(userId),
        'thumbs' => thumbs.contains(userId),
        'party'  => party.contains(userId),
        _        => false,
      };

      // Remove user from every reaction slot
      likedBy.remove(userId);
      thumbs.remove(userId);
      party.remove(userId);

      // Re-add only if not toggling off
      if (!isActive) {
        switch (reactionKey) {
          case 'love':   likedBy.add(userId); break;
          case 'thumbs': thumbs.add(userId);  break;
          case 'party':  party.add(userId);   break;
        }
      }

      txn.update(docRef, {
        'likedBy': likedBy,
        'reactions': {...reactionsRaw, 'thumbs': thumbs, 'party': party},
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  Future<void> editComment(
      String postId, PostComment oldComment, String newContent) async {
    final docRef = _postsRef.doc(postId);
    await _firestore.runTransaction((txn) async {
      final doc = await txn.get(docRef);
      final data = doc.data() ?? {};
      final comments = List<Map<String, dynamic>>.from(
          (data['comments'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)));
      final idx = comments.indexWhere((c) => c['id'] == oldComment.id);
      if (idx != -1) {
        comments[idx]['content'] = newContent;
      }
      txn.update(docRef, {
        'comments': comments,
        'updatedAt': FieldValue.serverTimestamp(),
      });
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

  // ===============================
  // Helpers
  // ===============================

  List<PostModel> _mapSnapshotToPosts(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) => PostModel.fromFirestore(doc)).toList();
  }
}
