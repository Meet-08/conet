import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileUpdatePersonalInfo {
  final UserProfileRepository _repository;

  ProfileUpdatePersonalInfo({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
  }) {
    return _repository.updatePersonalInfo(firstName, lastName, dateOfBirth);
  }
}
