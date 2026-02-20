// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfileModel _$UserProfileModelFromJson(Map<String, dynamic> json) =>
    UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      username: json['username'] as String?,
      aboutMe: json['about_me'] as String?,
      profilePicUrl: json['profile_pic_url'] as String?,
      bannerImageUrl: json['banner_image_url'] as String?,
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isVerified: json['is_verified'] as bool? ?? false,
      academics: const UserAcademicsListConverter().fromJson(
        json['user_academics'] as List,
      ),
      socialLinks:
          (json['social_links'] as List<dynamic>?)
              ?.map((e) => SocialLinks.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
    );

Map<String, dynamic> _$UserProfileModelToJson(UserProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'username': instance.username,
      'about_me': instance.aboutMe,
      'profile_pic_url': instance.profilePicUrl,
      'banner_image_url': instance.bannerImageUrl,
      'user_academics': const UserAcademicsListConverter().toJson(
        instance.academics,
      ),
      'interests': instance.interests,
      'social_links': instance.socialLinks.map((e) => e.toJson()).toList(),
      'is_verified': instance.isVerified,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'follower_count': instance.followerCount,
      'following_count': instance.followingCount,
      'is_following': instance.isFollowing,
    };
