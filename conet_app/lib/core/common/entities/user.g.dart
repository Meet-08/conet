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
  isVerified: json['is_verified'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'username': instance.username,
  'profile_pic_url': instance.profilePicUrl,
  'user_role': _$UserRoleEnumMap[instance.userRole]!,
  'is_verified': instance.isVerified,
};

const _$UserRoleEnumMap = {UserRole.user: 'user', UserRole.admin: 'admin'};
