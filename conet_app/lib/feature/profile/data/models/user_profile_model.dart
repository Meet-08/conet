import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/feature/profile/data/models/user_academics_model.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class UserProfileModel extends UserProfile {
  @override
  @JsonKey(name: 'user_academics')
  @UserAcademicsListConverter()
  final List<UserAcademics> academics;

  @override
  @JsonKey(defaultValue: [])
  final List<String> interests;

  @override
  @JsonKey(defaultValue: [])
  final List<SocialLinks> socialLinks;

  @override
  @JsonKey(defaultValue: false)
  final bool isVerified;

  @override
  final DateTime? dateOfBirth;

  @override
  @JsonKey(name: 'follower_count', defaultValue: 0)
  final int followerCount;

  @override
  @JsonKey(name: 'following_count', defaultValue: 0)
  final int followingCount;

  @override
  @JsonKey(name: 'is_following', defaultValue: false)
  final bool isFollowing;

  const UserProfileModel({
    required super.id,
    required super.email,
    super.firstName,
    super.lastName,
    super.username,
    super.aboutMe,
    super.profilePicUrl,
    super.bannerImageUrl,
    required this.interests,
    required this.isVerified,
    required this.academics,
    required this.socialLinks,
    this.dateOfBirth,
    this.followerCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  }) : super(
         isVerified: isVerified,
         academics: academics,
         socialLinks: socialLinks,
         interests: interests,
         dateOfBirth: dateOfBirth,
         followerCount: followerCount,
         followingCount: followingCount,
         isFollowing: isFollowing,
       );

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileModelToJson(this);

  factory UserProfileModel.fromEntity(UserProfile entity) {
    return UserProfileModel(
      id: entity.id,
      email: entity.email,
      firstName: entity.firstName,
      lastName: entity.lastName,
      username: entity.username,
      aboutMe: entity.aboutMe,
      profilePicUrl: entity.profilePicUrl,
      bannerImageUrl: entity.bannerImageUrl,
      interests: entity.interests,
      isVerified: entity.isVerified,
      academics: entity.academics,
      socialLinks: entity.socialLinks,
      dateOfBirth: entity.dateOfBirth,
      followerCount: entity.followerCount,
      followingCount: entity.followingCount,
      isFollowing: entity.isFollowing,
    );
  }
}
