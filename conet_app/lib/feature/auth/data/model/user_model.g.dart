// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  fullName: json['fullName'] as String? ?? '',
  username: json['username'] as String? ?? '',
  profilePicUrl: json['profilePicUrl'] as String? ?? '',
  userRole:
      $enumDecodeNullable(_$UserRoleEnumMap, json['userRole']) ?? UserRole.user,
  isVerified: json['isVerified'] as bool? ?? false,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'username': instance.username,
  'profilePicUrl': instance.profilePicUrl,
  'userRole': _$UserRoleEnumMap[instance.userRole]!,
  'isVerified': instance.isVerified,
};

const _$UserRoleEnumMap = {UserRole.user: 'user', UserRole.admin: 'admin'};
