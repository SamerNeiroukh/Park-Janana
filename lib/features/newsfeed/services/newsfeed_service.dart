import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

class NewsfeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'posts';

  /// Get all posts as a stream, ordered by pinned first, then by date
  Stream<List<PostModel>> getPostsStream() {
    return _firestore
        .collection(_collection)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  /// Get a single post by ID
  Future<PostModel?> getPost(String postId) async {
    final doc = await _firestore.collection(_collection).doc(postId).get();
    if (!doc.exists) return null;
    return PostModel.fromFirestore(doc);
  }

  /// Create a new post
  Future<void> createPost(PostModel post) async {
    await _firestore.collection(_collection).doc(post.id).set(post.toMap());
  }

  /// Update an existing post
  Future<void> updatePost(String postId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(_collection).doc(postId).update(updates);
  }

  /// Delete a post
  Future<void> deletePost(String postId) async {
    await _firestore.collection(_collection).doc(postId).delete();
  }

  /// Toggle pin status
  Future<void> togglePin(String postId, bool isPinned) async {
    await _firestore.collection(_collection).doc(postId).update({
      'isPinned': isPinned,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a like to a post
  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection(_collection).doc(postId).update({
      'likedBy': FieldValue.arrayUnion([userId]),
    });
  }

  /// Remove a like from a post
  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection(_collection).doc(postId).update({
      'likedBy': FieldValue.arrayRemove([userId]),
    });
  }

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

    await _firestore.collection(_collection).doc(postId).update({
      'comments': FieldValue.arrayUnion([comment.toMap()]),
    });
  }

  /// Delete a comment from a post
  Future<void> deleteComment(String postId, PostComment comment) async {
    await _firestore.collection(_collection).doc(postId).update({
      'comments': FieldValue.arrayRemove([comment.toMap()]),
    });
  }

  /// Get posts by category
  Stream<List<PostModel>> getPostsByCategory(String category) {
    return _firestore
        .collection(_collection)
        .where('category', isEqualTo: category)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }
}
