import 'package:conet_app/core/common/entities/user.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

class Post extends Equatable {
  final String id;
  final User user;
  final String content;

  @JsonKey(name: 'media_urls', defaultValue: [])
  final List<String> mediaUrls;

  @JsonKey(name: 'like_count', defaultValue: 0)
  final int likeCount;

  @JsonKey(name: 'comment_count', defaultValue: 0)
  final int commentCount;

  @JsonKey(name: 'is_liked', defaultValue: false)
  final bool isLiked;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const Post({
    required this.id,
    required this.user,
    required this.content,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
    required this.createdAt,
  });

  Post copyWith({
    String? id,
    User? user,
    String? content,
    List<String>? mediaUrls,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return Post(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    user,
    content,
    mediaUrls,
    likeCount,
    commentCount,
    isLiked,
    createdAt,
  ];
}
