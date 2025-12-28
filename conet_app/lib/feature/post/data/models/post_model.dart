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
  });

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);

  Map<String, dynamic> toJson() => _$PostModelToJson(this);

  PostModel copyWith({
    String? id,
    User? user,
    String? content,
    List<String>? mediaUrls,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return PostModel(
      id: id ?? this.id,
      user: user ?? this.user,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}
