import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserSendOtp {
  final AuthRepository _authRepository;

  UserSendOtp({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<AppFailure, bool>> call({
    required String email,
    required String firstName,
    String? lastName,
  }) {
    return _authRepository.sendOtp(
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
  }
}
