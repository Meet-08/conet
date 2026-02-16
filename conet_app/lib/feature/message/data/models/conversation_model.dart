import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/message/domain/entities/conversation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'conversation_model.g.dart';

@JsonSerializable()
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.otherUser,
    super.lastMessage,
    super.updatedAt,
    super.unreadCount,
    super.lastMessageMediaUrls,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) =>
      _$ConversationModelFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);
}
