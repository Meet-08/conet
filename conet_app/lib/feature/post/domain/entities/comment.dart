import 'package:json_annotation/json_annotation.dart';

class Comment {
  final String id;

  @JsonKey(name: "post_id")
  final String postId;

  @JsonKey(name: "user_id")
  final String userId;

  final String username;

  @JsonKey(name: "profile_pic_url")
  final String? profilePicUrl;

  final String content;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.profilePicUrl,
    required this.content,
  });
}
