import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class ProfileUpdatePictures {
  final UserProfileRepository _repository;

  ProfileUpdatePictures({required UserProfileRepository repository})
    : _repository = repository;

  Future<Either<AppFailure, Unit>> call({
    PlatformFile? profilePic,
    PlatformFile? bannerImage,
  }) {
    return _repository.updatePictures(profilePic, bannerImage);
  }
}
