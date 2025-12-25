import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserCurrent {
  final AuthRepository _authRepository;

  UserCurrent({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<AppFailure, User>> call() async {
    return _authRepository.currentUser();
  }
}
