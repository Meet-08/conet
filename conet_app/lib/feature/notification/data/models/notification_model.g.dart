// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    NotificationModel(
      id: json['id'] as String,
      actorId: json['actor_id'] as String,
      receiverId: json['receiver_id'] as String,
      isSeen: json['is_seen'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      content: json['content'] as String?,
      type: json['type'] as String,
      actorFirstName: json['actor_first_name'] as String?,
      actorLastName: json['actor_last_name'] as String?,
      actorUsername: json['actor_username'] as String?,
      actorProfilePicUrl: json['actor_profile_pic_url'] as String?,
    );

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'actor_id': instance.actorId,
      'receiver_id': instance.receiverId,
      'is_seen': instance.isSeen,
      'created_at': instance.createdAt.toIso8601String(),
      'content': instance.content,
      'type': instance.type,
      'actor_first_name': instance.actorFirstName,
      'actor_last_name': instance.actorLastName,
      'actor_username': instance.actorUsername,
      'actor_profile_pic_url': instance.actorProfilePicUrl,
    };
