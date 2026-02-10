// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String,
      aboutMe: json['aboutMe'] as String?,
      profilePicUrl: json['profilePicUrl'] as String?,
      bannerImageUrl: json['bannerImageUrl'] as String?,
      interests: (json['interests'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isVerified: json['isVerified'] as bool,
      academics: const UserAcademicsListConverter().fromJson(
        json['academics'] as List,
      ),
      socialLinks: (json['socialLinks'] as List<dynamic>)
          .map((e) => SocialLinks.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserProfileModelToJson(
  UserProfileModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'username': instance.username,
  'aboutMe': instance.aboutMe,
  'profilePicUrl': instance.profilePicUrl,
  'bannerImageUrl': instance.bannerImageUrl,
  'interests': instance.interests,
  'isVerified': instance.isVerified,
  'academics': const UserAcademicsListConverter().toJson(instance.academics),
  'socialLinks': instance.socialLinks.map((e) => e.toJson()).toList(),
};
