import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserLogin {
  final AuthRepository _authRepository;

  UserLogin({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<AppFailure, User>> call({
    required String email,
    required String password,
  }) {
    return _authRepository.loginWithEmailPassword(
      email: email,
      password: password,
    );
  }
}
