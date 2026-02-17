part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSendOtp extends AuthEvent {
  final String email;
  final String firstName;
  final String? lastName;

  AuthSendOtp({required this.email, required this.firstName, this.lastName});
}

final class AuthVerifyOtp extends AuthEvent {
  final String email;
  final String otp;

  AuthVerifyOtp({required this.email, required this.otp});
}

final class AuthLogin extends AuthEvent {
  final String email;
  final String password;

  AuthLogin({required this.email, required this.password});
}

final class AuthSigninWithGoogle extends AuthEvent {}

final class AuthAddDetails extends AuthEvent {
  final String username;
  final String? firstName;
  final String? lastName;
  final String? password;

  AuthAddDetails({
    required this.username,
    this.firstName,
    this.lastName,
    this.password,
  });
}

final class AuthIsUserLoggedIn extends AuthEvent {}

final class AuthLogout extends AuthEvent {}
