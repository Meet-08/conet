import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/profile/data/data_sources/profile_data_source.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final ProfileDataSource profileDataSource;

  UserProfileRepositoryImpl({required this.profileDataSource});

  @override
  Future<Either<AppFailure, Unit>> updatePictures(
    PlatformFile? profilePic,
    PlatformFile? bannerImage,
  ) async {
    return _performUpdate(
      () => profileDataSource.updatePictures(
        profilePic: profilePic,
        bannerImage: bannerImage,
      ),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> updatePersonalInfo(
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  ) async {
    return _performUpdate(
      () => profileDataSource.updatePersonalInfo(
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
      ),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> updateAboutMe(String aboutMe) async {
    return _performUpdate(() => profileDataSource.updateAboutMe(aboutMe));
  }

  @override
  Future<Either<AppFailure, Unit>> updateInterests(
    List<String> interests,
  ) async {
    return _performUpdate(() => profileDataSource.updateInterests(interests));
  }

  @override
  Future<Either<AppFailure, Unit>> updateAcademicInfo({
    required String collegeName,
    required String course,
    String? major,
    int? startYear,
    int? endYear,
  }) async {
    return _performUpdate(
      () => profileDataSource.updateAcademicInfo(
        collegeName: collegeName,
        course: course,
        major: major,
        startYear: startYear,
        endYear: endYear,
      ),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> updateSocialLinks(
    List<SocialLinks> socialLinks,
  ) async {
    return _performUpdate(
      () => profileDataSource.updateSocialLinks(socialLinks),
    );
  }

  @override
  Future<Either<AppFailure, UserProfile>> getUserProfile(String uid) async {
    try {
      final userProfile = await profileDataSource.getUserProfile(uid);
      return right(userProfile);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    } catch (e) {
      return left(AppFailure(e.toString()));
    }
  }

  Future<Either<AppFailure, Unit>> _performUpdate(
    Future<User> Function() updateAction,
  ) async {
    try {
      await updateAction();
      return right(unit);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    } catch (e) {
      return left(AppFailure(e.toString()));
    }
  }
}
