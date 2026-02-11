import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class UserProfileRepository {
  Future<Either<AppFailure, Unit>> updatePictures(
    PlatformFile? profilePic,
    PlatformFile? bannerImage,
  );

  Future<Either<AppFailure, Unit>> updatePersonalInfo(
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  );

  Future<Either<AppFailure, Unit>> updateAboutMe(String aboutMe);

  Future<Either<AppFailure, Unit>> updateInterests(List<String> interests);

  Future<Either<AppFailure, Unit>> updateAcademicInfo({
    required String collegeName,
    required String course,
    String? major,
    int? startYear,
    int? endYear,
  });

  Future<Either<AppFailure, Unit>> updateSocialLinks(
    List<SocialLinks> socialLinks,
  );

  Future<Either<AppFailure, UserProfile>> getUserProfile(String uid);
}
