part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSendOtp extends AuthEvent {
  final String email;

  AuthSendOtp({required this.email});
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

final class AuthIsUserLoggedIn extends AuthEvent {}
