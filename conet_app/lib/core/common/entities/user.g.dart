// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String,
  email: json['email'] as String? ?? '',
  firstName: json['first_name'] as String? ?? '',
  lastName: json['last_name'] as String? ?? '',
  username: json['username'] as String? ?? '',
  profilePicUrl: json['profile_pic_url'] as String?,
  userRole:
      $enumDecodeNullable(_$UserRoleEnumMap, json['user_role']) ??
      UserRole.user,
  unseenNotificationCount:
      (json['unseen_notification_count'] as num?)?.toInt() ?? 0,
  isOnline: json['is_online'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'username': instance.username,
  'profile_pic_url': instance.profilePicUrl,
  'user_role': _$UserRoleEnumMap[instance.userRole]!,
  'unseen_notification_count': instance.unseenNotificationCount,
  'is_online': instance.isOnline,
};

const _$UserRoleEnumMap = {UserRole.user: 'user', UserRole.admin: 'admin'};
