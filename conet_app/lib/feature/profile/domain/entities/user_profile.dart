import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? aboutMe;
  final String? profilePicUrl;
  final String? bannerImageUrl;
  final List<String> interests;
  final bool isVerified;
  final List<SocialLinks> socialLinks;
  final List<UserAcademics> academics;
  final DateTime? dateOfBirth;
  final int followerCount;
  final int followingCount;

  const UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.username,
    this.aboutMe,
    this.profilePicUrl,
    this.bannerImageUrl,
    required this.interests,
    required this.isVerified,
    required this.academics,
    required this.socialLinks,
    this.dateOfBirth,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    firstName,
    lastName,
    username,
    aboutMe,
    profilePicUrl,
    bannerImageUrl,
    interests,
    isVerified,
    academics,
    dateOfBirth,
    followerCount,
    followingCount,
  ];
}
