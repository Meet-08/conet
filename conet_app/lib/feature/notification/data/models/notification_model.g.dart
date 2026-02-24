// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

// Note: fromJson is manually implemented in NotificationModel to handle
// the nested actor join. Only toJson is generated here.

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'actor_id': instance.actorId,
      'receiver_id': instance.receiverId,
      'is_seen': instance.isSeen,
      'created_at': instance.createdAt.toIso8601String(),
      'content': instance.content,
      'type': instance.type,
    };
