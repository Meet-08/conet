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
  Future<Either<AppFailure, User>> currentUser() async {
    try {
      final session = _authDataSource.currentUserSession;
      if (session == null) return left(AppFailure('User not logged in!'));

      final user = await _authDataSource.currentUser();
      if (user == null) return left(AppFailure('User data not found!'));

      return right(user);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    }
  }

  @override
  Future<Either<AppFailure, User>> signInWithGoogle() async {
    return _getUser(() async => await _authDataSource.signInWithGoogle());
  }

  @override
  Future<Either<AppFailure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _getUser(
      () async => await _authDataSource.loginWithEmailPassword(
        email: email,
        password: password,
      ),
    );
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

  @override
  Future<Either<AppFailure, User>> addDetails({
    required String username,
    String? firstName,
    String? lastName,
    String? password,
  }) {
    return _getUser(
      () async => await _authDataSource.addDetails(
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
      ),
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
  Future<Either<AppFailure, bool>> sendOtp({
    required String email,
    required String firstName,
    String? lastName,
  }) async {
    try {
      final result = await _authDataSource.sendOtp(
        email: email,
        firstName: firstName,
        lastName: lastName,
      );
      return right(result);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    }
  }

  @override
  Future<Either<AppFailure, bool>> checkUsernameAvailable(
    String username,
  ) async {
    try {
      final result = await _authDataSource.checkUsernameAvailable(username);
      return right(result);
    } on ServerException catch (e) {
      return left(AppFailure(e.message));
    }
  }
}
