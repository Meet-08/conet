import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<AppFailure, User>> currentUser();

  Future<Either<AppFailure, User>> signInWithGoogle();

  Future<Either<AppFailure, bool>> sendOtp({
    required String email,
    required String firstName,
    String? lastName,
  });

  Future<Either<AppFailure, User>> verifyOtp({
    required String email,
    required String token,
  });

  Future<Either<AppFailure, User>> addDetails({
    required String username,
    String? firstName,
    String? lastName,
    String? password,
  });

  Future<Either<AppFailure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  });

  /// Checks if username is available (not taken)
  Future<Either<AppFailure, bool>> checkUsernameAvailable(String username);

  Future<Either<AppFailure, Unit>> logout();
}
