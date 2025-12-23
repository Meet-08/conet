import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserSigninWithGoogle {
  final AuthRepository _authRepository;

  UserSigninWithGoogle({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<AppFailure, User>> call() async {
    return await _authRepository.signInWithGoogle();
  }
}
