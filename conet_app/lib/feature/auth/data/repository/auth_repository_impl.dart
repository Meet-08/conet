import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource _authDataSource;

  AuthRepositoryImpl({required AuthDataSource authDataSource})
    : _authDataSource = authDataSource;

  @override
  Future<Either<AppFailure, User>> currentUser() {
    // TODO: implement currentUser
    throw UnimplementedError();
  }

  @override
  Future<Either<AppFailure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  }) {
    // TODO: implement loginWithEmailPassword
    throw UnimplementedError();
  }

  @override
  Future<Either<AppFailure, User>> verifyOtp({
    required String email,
    required String token,
  }) {
    return _getUser(
      () async => await _authDataSource.verifyOtp(email: email, token: token),
    );
  }

  Future<Either<AppFailure, User>> _getUser(Future<User> Function() fn) async {
    try {
      final user = await fn();
      return right(user);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    }
  }

  @override
  Future<Either<AppFailure, bool>> sendOtp({required String email}) async {
    try {
      final result = await _authDataSource.sendOtp(email: email);
      return right(result);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    }
  }
}
