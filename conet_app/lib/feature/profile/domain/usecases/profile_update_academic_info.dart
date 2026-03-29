import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileUpdateAcademicInfo {
  final UserProfileRepository _repository;

  ProfileUpdateAcademicInfo({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call({
    required String collegeName,
    required String degree,
    required String course,
    int? startYear,
    int? endYear,
  }) {
    return _repository.updateAcademicInfo(
      collegeName: collegeName,
      degree: degree,
      course: course,
      startYear: startYear,
      endYear: endYear,
    );
  }
}
