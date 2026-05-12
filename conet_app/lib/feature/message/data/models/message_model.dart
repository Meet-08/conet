import 'package:conet_app/feature/message/domain/entities/message.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel extends Message {
  @JsonKey(name: 'post')
  final PostModel? postModel;

  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    super.content,
    required super.createdAt,
    super.isRead,
    super.mediaUrls = const [],
    super.status,
    super.isPost,
    super.postId,
    this.postModel,
  }) : super(post: postModel);

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}
