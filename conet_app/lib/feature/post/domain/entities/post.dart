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

  const Post({
    required this.id,
    required this.user,
    required this.content,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.isLiked,
  });

  @override
  List<Object?> get props => [
    id,
    user,
    content,
    mediaUrls,
    likeCount,
    commentCount,
  ];
}
