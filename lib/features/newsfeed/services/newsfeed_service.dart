import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

class NewsfeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'posts';

  CollectionReference<Map<String, dynamic>> get _postsRef =>
      _firestore.collection(_collectionName);

  // ===============================
  // Streams
  // ===============================

  /// Get all posts ordered by:
  /// 1. Pinned posts first
  /// 2. Newest posts first
  Stream<List<PostModel>> getPostsStream() {
    return _postsRef
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(_mapSnapshotToPosts);
  }

  /// Get posts filtered by category
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

  /// Fetch a single post by ID
  Future<PostModel?> getPost(String postId) async {
    final doc = await _postsRef.doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  // ===============================
  // Mutations
  // ===============================

  /// Create a new post
  Future<void> createPost(PostModel post) async {
    await _postsRef.doc(post.id).set(post.toMap());
  }

  /// Update an existing post
  Future<void> updatePost(
    String postId,
    Map<String, dynamic> updates,
  ) async {
    await _postsRef.doc(postId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a post permanently
  Future<void> deletePost(String postId) async {
    await _postsRef.doc(postId).delete();
  }

  /// Pin or unpin a post
  Future<void> togglePin(String postId, bool isPinned) async {
    await _postsRef.doc(postId).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ===============================
  // Likes
  // ===============================

  /// Add like from user
  Future<void> likePost(String postId, String userId) async {
    await _postsRef.doc(postId).update({
      'likedBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove like from user
  Future<void> unlikePost(String postId, String userId) async {
    await _postsRef.doc(postId).update({
      'likedBy': FieldValue.arrayRemove([userId]),
    });
  }

  // ===============================
  // Comments (array-based)
  // ===============================
  // NOTE:
  // This works well for small-to-medium scale.
  // In the future, comments should move to a subcollection.

  /// Add a comment to a post
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

  /// Remove a comment from a post
  Future<void> deleteComment(String postId, PostComment comment) async {
    await _postsRef.doc(postId).update({
      'comments': FieldValue.arrayRemove([comment.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
