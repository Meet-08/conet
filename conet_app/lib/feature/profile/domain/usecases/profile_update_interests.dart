import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileUpdateInterests {
  final UserProfileRepository _repository;

  ProfileUpdateInterests({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call(List<String> interests) {
    return _repository.updateInterests(interests);
  }
}
