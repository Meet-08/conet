part of 'profile_connections_bloc.dart';

@immutable
sealed class ProfileConnectionsEvent {}

class ProfileConnectionsLoadRequested extends ProfileConnectionsEvent {
  final String uid;

  ProfileConnectionsLoadRequested({required this.uid});
}
