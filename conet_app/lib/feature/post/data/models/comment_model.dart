import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:json_annotation/json_annotation.dart';

part 'comment_model.g.dart';

@JsonSerializable()
class CommentModel extends Comment {
  @override
  @JsonKey(name: "replies")
  final List<CommentModel> replies;

  CommentModel({
    required super.id,
    required super.postId,
    required super.userId,
    required super.username,
    required super.profilePicUrl,
    required super.content,
    super.parentCommentId,
    this.replies = const [],
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) =>
      _$CommentModelFromJson(json);

  Map<String, dynamic> toJson() => _$CommentModelToJson(this);

  static CommentModel copyWith(CommentModel comment) {
    return CommentModel(
      id: comment.id,
      postId: comment.postId,
      userId: comment.userId,
      username: comment.username,
      profilePicUrl: comment.profilePicUrl,
      content: comment.content,
      parentCommentId: comment.parentCommentId,
      replies: comment.replies.map((r) => CommentModel.copyWith(r)).toList(),
    );
  }
}
