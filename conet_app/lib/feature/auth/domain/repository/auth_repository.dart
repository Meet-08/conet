import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class AuthRepository {
  Future<Either<AppFailure, User>> currentUser();

  Future<Either<AppFailure, User>> signInWithGoogle();

  Future<Either<AppFailure, bool>> sendOtp({required String email});

  Future<Either<AppFailure, User>> verifyOtp({
    required String email,
    required String token,
  });

  Future<Either<AppFailure, User>> addDetails({
    required String username,
    required String password,
  });

  Future<Either<AppFailure, User>> loginWithEmailPassword({
    required String email,
    required String password,
  });
}
