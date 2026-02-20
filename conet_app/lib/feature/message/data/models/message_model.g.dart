// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  senderId: json['sender_id'] as String,
  content: json['content'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  isRead: json['is_read'] as bool? ?? false,
  mediaUrls:
      (json['media_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  status:
      $enumDecodeNullable(_$MessageDeliveryStatusEnumMap, json['status']) ??
      MessageDeliveryStatus.sent,
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'created_at': instance.createdAt.toIso8601String(),
      'is_read': instance.isRead,
      'media_urls': instance.mediaUrls,
      'status': _$MessageDeliveryStatusEnumMap[instance.status]!,
    };

const _$MessageDeliveryStatusEnumMap = {
  MessageDeliveryStatus.pending: 'pending',
  MessageDeliveryStatus.sent: 'sent',
  MessageDeliveryStatus.error: 'error',
};
