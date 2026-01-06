import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:json_annotation/json_annotation.dart';

part 'post_model.g.dart';

@JsonSerializable()
class PostModel extends Post {
  const PostModel({
    required super.id,
    required super.user,
    required super.content,
    required super.mediaUrls,
    required super.likeCount,
    required super.commentCount,
    required super.isLiked,
    required super.createdAt,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);
}
