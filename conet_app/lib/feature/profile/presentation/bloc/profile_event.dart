part of 'profile_bloc.dart';

@immutable
sealed class ProfileEvent {}

class ProfileUpdatePersonalInfoEvent extends ProfileEvent {
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;

  ProfileUpdatePersonalInfoEvent({
    this.firstName,
    this.lastName,
    this.dateOfBirth,
  });
}

class ProfileUpdateAboutMeEvent extends ProfileEvent {
  final String aboutMe;

  ProfileUpdateAboutMeEvent({required this.aboutMe});
}

class ProfileUpdateInterestsEvent extends ProfileEvent {
  final List<String> interests;

  ProfileUpdateInterestsEvent({required this.interests});
}

class ProfileUpdateAcademicInfoEvent extends ProfileEvent {
  final String collegeName;
  final String course;
  final String? major;
  final int? startYear;
  final int? endYear;

  ProfileUpdateAcademicInfoEvent({
    required this.collegeName,
    required this.course,
    this.major,
    this.startYear,
    this.endYear,
  });
}

class ProfileUpdateSocialLinksEvent extends ProfileEvent {
  final List<SocialLinks> socialLinks;

  ProfileUpdateSocialLinksEvent({required this.socialLinks});
}

class ProfileUpdatePicturesEvent extends ProfileEvent {
  final PlatformFile? profilePic;
  final PlatformFile? bannerImage;

  ProfileUpdatePicturesEvent({this.profilePic, this.bannerImage});
}

class ProfileGetEvent extends ProfileEvent {
  final String uid;

  ProfileGetEvent({required this.uid});
}

class ProfileFollowUserEvent extends ProfileEvent {
  final String targetUid;

  ProfileFollowUserEvent({required this.targetUid});
}

class ProfileUnfollowUserEvent extends ProfileEvent {
  final String targetUid;

  ProfileUnfollowUserEvent({required this.targetUid});
}
