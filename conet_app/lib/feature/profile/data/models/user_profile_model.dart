import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/feature/profile/data/models/user_academics_model.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfileModel extends UserProfile {
  @override
  @UserAcademicsListConverter()
  final List<UserAcademics> academics;

  @override
  final List<SocialLinks> socialLinks;

  const UserProfileModel({
    required super.id,
    required super.email,
    required super.firstName,
    required super.lastName,
    required super.username,
    super.aboutMe,
    super.profilePicUrl,
    super.bannerImageUrl,
    required super.interests,
    required super.isVerified,
    required this.academics,
    required this.socialLinks,
  }) : super(academics: academics, socialLinks: socialLinks);

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
    );
  }
}
