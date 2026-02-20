import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:file_picker/file_picker.dart';

abstract interface class ProfileDataSource {
  Future<UserModel> updatePictures({
    PlatformFile? profilePic,
    PlatformFile? bannerImage,
  });

  Future<UserProfile> getUserProfile(String uid);

  Future<UserModel> updatePersonalInfo({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  });

  Future<UserModel> updateAboutMe(String aboutMe);

  Future<UserModel> updateInterests(List<String> interests);

  Future<UserModel> updateAcademicInfo({
    required String collegeName,
    required String course,
    String? major,
    int? startYear,
    int? endYear,
  });

  Future<UserModel> updateSocialLinks(List<SocialLinks> socialLinks);

  Future<void> followUser(String targetUid);

  Future<void> unfollowUser(String targetUid);
}
