import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileUpdateAboutMe {
  final UserProfileRepository _repository;

  ProfileUpdateAboutMe({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call(String aboutMe) {
    return _repository.updateAboutMe(aboutMe);
  }
}
