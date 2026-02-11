import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class ProfileUpdateSocialLinks {
  final UserProfileRepository _repository;

  ProfileUpdateSocialLinks({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call(List<SocialLinks> socialLinks) {
    return _repository.updateSocialLinks(socialLinks);
  }
}
