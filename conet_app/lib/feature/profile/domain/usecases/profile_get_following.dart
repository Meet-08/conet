import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileGetFollowing {
  final UserProfileRepository _repository;

  ProfileGetFollowing({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, List<User>>> call(String uid) {
    return _repository.getFollowing(uid);
  }
}
