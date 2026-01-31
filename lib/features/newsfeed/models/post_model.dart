import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a comment on a post
class PostComment {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePicture;
  final String content;
  final Timestamp createdAt;

  PostComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfilePicture,
    required this.content,
    required this.createdAt,
  });

  factory PostComment.fromMap(Map<String, dynamic> map) {
    return PostComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfilePicture: map['userProfilePicture'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
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

/// Model for a newsfeed post
class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorRole;
  final String authorProfilePicture;
  final String title;
  final String content;
  final String? imageUrl;
  final String category; // announcement, update, event, general
  final bool isPinned;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final List<PostComment> comments;
  final List<String> likedBy;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.authorProfilePicture,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.category,
    this.isPinned = false,
    required this.createdAt,
    this.updatedAt,
    this.comments = const [],
    this.likedBy = const [],
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorRole: data['authorRole'] ?? '',
      authorProfilePicture: data['authorProfilePicture'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'general',
      isPinned: data['isPinned'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      comments: (data['comments'] as List<dynamic>?)
              ?.map((c) => PostComment.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorProfilePicture': authorProfilePicture,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'category': category,
      'isPinned': isPinned,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'comments': comments.map((c) => c.toMap()).toList(),
      'likedBy': likedBy,
    };
  }

  PostModel copyWith({
    String? id,
    String? authorId,
    String? authorName,
    String? authorRole,
    String? authorProfilePicture,
    String? title,
    String? content,
    String? imageUrl,
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
      category: category ?? this.category,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      comments: comments ?? this.comments,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  int get likesCount => likedBy.length;
  int get commentsCount => comments.length;

  bool isLikedBy(String userId) => likedBy.contains(userId);

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
