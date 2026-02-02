import 'package:cloud_firestore/cloud_firestore.dart';

/// ===============================
/// Media Model (for posts)
/// ===============================
class PostMedia {
  final String url;
  final String type; // 'image' or 'video'
  final String? thumbnailUrl; // For videos

  const PostMedia({
    required this.url,
    required this.type,
    this.thumbnailUrl,
  });

  bool get isVideo => type == 'video';
  bool get isImage => type == 'image';

  factory PostMedia.fromMap(Map<String, dynamic> map) {
    return PostMedia(
      url: map['url'] as String? ?? '',
      type: map['type'] as String? ?? 'image',
      thumbnailUrl: map['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type,
      if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
    };
  }
}

/// ===============================
/// Comment Model
/// ===============================
class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePicture;
  final String content;
  final Timestamp createdAt;

  const PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfilePicture,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromMap(Map<String, dynamic> map) {
    return PostComment(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userProfilePicture: map['userProfilePicture'] as String? ?? '',
      content: map['content'] as String? ?? '',
      createdAt:
          map['createdAt'] is Timestamp ? map['createdAt'] : Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'content': content,
      'createdAt': createdAt,
    };
  }
}

/// ===============================
/// Post Model
/// ===============================
class PostModel {
  final String id;

  // Author
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorProfilePicture;

  // Content
  final String title;
  final String content;
  final String? imageUrl; // Legacy - kept for backward compatibility
  final List<PostMedia> media; // New - supports multiple photos/videos
  final String category; // announcement | update | event | general

  // Metadata
  final bool isPinned;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  // Engagement
  final List<PostComment> comments;
  final List<String> likedBy;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorProfilePicture,
    required this.title,
    required this.content,
    this.imageUrl,
    this.media = const [],
    required this.category,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
    this.comments = const [],
    this.likedBy = const [],
  });

  /// -------------------------------
  /// Firestore → Model
  /// -------------------------------
  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return PostModel(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorRole: data['authorRole'] as String? ?? '',
      authorProfilePicture: data['authorProfilePicture'] as String? ?? '',
      title: data['title'] as String? ?? '',
      content: data['content'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      media: (data['media'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PostMedia.fromMap)
              .toList() ??
          const [],
      category: data['category'] as String? ?? 'general',
      isPinned: data['isPinned'] as bool? ?? false,
      createdAt:
          data['createdAt'] is Timestamp ? data['createdAt'] : Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp?,
      comments: (data['comments'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(PostComment.fromMap)
              .toList() ??
          const [],
      likedBy: List<String>.from(data['likedBy'] ?? const []),
    );
  }

  /// -------------------------------
  /// Model → Firestore
  /// -------------------------------
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorProfilePicture': authorProfilePicture,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'media': media.map((m) => m.toMap()).toList(),
      'category': category,
      'isPinned': isPinned,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'comments': comments.map((c) => c.toMap()).toList(),
      'likedBy': likedBy,
    };
  }

  /// -------------------------------
  /// Copy helper
  /// -------------------------------
  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? authorProfilePicture,
    String? title,
    String? content,
    String? imageUrl,
    List<PostMedia>? media,
    String? category,
    bool? isPinned,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    List<PostComment>? comments,
    List<String>? likedBy,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorProfilePicture: authorProfilePicture ?? this.authorProfilePicture,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      media: media ?? this.media,
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  /// -------------------------------
  /// Helpers
  /// -------------------------------
  int get likesCount => likedBy.length;
  int get commentsCount => comments.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

  /// Check if post has any media (new media array or legacy imageUrl)
  bool get hasMedia => media.isNotEmpty || (imageUrl != null && imageUrl!.isNotEmpty);

  /// Get all media items (combines legacy imageUrl with new media array)
  List<PostMedia> get allMedia {
    final List<PostMedia> result = [...media];
    // Add legacy imageUrl as first item if exists and media is empty
    if (media.isEmpty && imageUrl != null && imageUrl!.isNotEmpty) {
      result.add(PostMedia(url: imageUrl!, type: 'image'));
    }
    return result;
  }

  String get categoryDisplayName {
    switch (category) {
      case 'announcement':
        return 'הודעה';
      case 'update':
        return 'עדכון';
      case 'event':
        return 'אירוע';
      default:
        return 'כללי';
    }
  }
}
