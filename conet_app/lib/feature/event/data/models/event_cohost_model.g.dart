// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_cohost_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventCohostModel _$EventCohostModelFromJson(Map<String, dynamic> json) =>
    EventCohostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePicUrl: json['profile_pic_url'] as String?,
    );

Map<String, dynamic> _$EventCohostModelToJson(EventCohostModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'username': instance.username,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_pic_url': instance.profilePicUrl,
    };
