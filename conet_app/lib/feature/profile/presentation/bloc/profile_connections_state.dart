part of 'profile_connections_bloc.dart';

@immutable
sealed class ProfileConnectionsState {}

final class ProfileConnectionsInitial extends ProfileConnectionsState {}

final class ProfileConnectionsLoading extends ProfileConnectionsState {}

final class ProfileConnectionsLoaded extends ProfileConnectionsState {
  final List<User> followers;
  final List<User> following;

  ProfileConnectionsLoaded({required this.followers, required this.following});
}

final class ProfileConnectionsFailure extends ProfileConnectionsState {
  final String error;

  ProfileConnectionsFailure({required this.error});
}
