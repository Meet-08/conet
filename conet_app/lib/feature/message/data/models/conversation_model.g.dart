// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationModel _$ConversationModelFromJson(Map<String, dynamic> json) =>
    ConversationModel(
      id: json['id'] as String,
      otherUser: User.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] as String?,
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ConversationModelToJson(ConversationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'other_user': instance.otherUser,
      'last_message': instance.lastMessage,
      'updated_at': instance.updatedAt?.toIso8601String(),
      'unread_count': instance.unreadCount,
    };
