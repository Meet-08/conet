import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserLogout {
  final AuthRepository authRepository;

  UserLogout(this.authRepository);

  Future<Either<AppFailure, Unit>> call() async {
    return await authRepository.logout();
  }
}
