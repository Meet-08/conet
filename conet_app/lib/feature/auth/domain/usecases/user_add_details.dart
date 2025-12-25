import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserAddDetails {
  final AuthRepository _authRepository;

  UserAddDetails({required AuthRepository authRepository})
    : _authRepository = authRepository;

  Future<Either<AppFailure, User>> call({
    required String username,
    String? firstName,
    String? lastName,
    String? password,
  }) async {
    return _authRepository.addDetails(
      username: username,
      firstName: firstName,
      lastName: lastName,
      password: password,
    );
  }
}
