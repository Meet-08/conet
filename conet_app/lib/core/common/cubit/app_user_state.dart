part of 'app_user_cubit.dart';

@immutable
sealed class AppUserState {}

final class AppUserUnknown extends AppUserState {}

final class AppUserUnauthenticated extends AppUserState {}

final class AppUserAuthenticated extends AppUserState {
  final User user;
  AppUserAuthenticated(this.user);
}
