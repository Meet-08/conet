part of 'auth_bloc.dart';

@immutable
sealed class AuthState {
  const AuthState();
}

final class AuthInitial extends AuthState {}

enum AuthLoadingAction {
  login,
  sendOtp,
  verifyOtp,
  googleSignIn,
  addDetails,
  currentUser,
  logout,
}

final class AuthLoading extends AuthState {
  final AuthLoadingAction action;

  const AuthLoading(this.action);
}

final class AuthOtpSentSuccess extends AuthState {}

final class AuthSuccess extends AuthState {
  final User user;
  final bool isNewUser;
  const AuthSuccess(this.user, {this.isNewUser = false});
}

final class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
}
