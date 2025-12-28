// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PostModel _$PostModelFromJson(Map<String, dynamic> json) => PostModel(
  id: json['id'] as String,
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  content: json['content'] as String,
  mediaUrls:
      (json['media_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
  commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
  isLiked: json['is_liked'] as bool? ?? false,
);

Map<String, dynamic> _$PostModelToJson(PostModel instance) => <String, dynamic>{
  'id': instance.id,
  'user': instance.user,
  'content': instance.content,
  'media_urls': instance.mediaUrls,
  'like_count': instance.likeCount,
  'comment_count': instance.commentCount,
  'is_liked': instance.isLiked,
};
