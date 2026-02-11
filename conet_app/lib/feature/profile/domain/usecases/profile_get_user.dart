import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileGetUser {
  final UserProfileRepository userProfileRepository;

  ProfileGetUser({required this.userProfileRepository});

  Future<Either<AppFailure, UserProfile>> call(String params) async {
    return await userProfileRepository.getUserProfile(params);
  }
}
