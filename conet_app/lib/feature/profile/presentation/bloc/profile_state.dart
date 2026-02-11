part of 'profile_bloc.dart';

@immutable
sealed class ProfileState {}

final class ProfileInitial extends ProfileState {}

final class ProfileLoading extends ProfileState {}

final class ProfileLoaded extends ProfileState {
  final UserProfile userProfile;

  ProfileLoaded(this.userProfile);
}

final class ProfileUpdateSuccess extends ProfileState {
  final String message;

  ProfileUpdateSuccess({this.message = 'Profile updated successfully'});
}

final class ProfileUpdateFailure extends ProfileState {
  final String error;

  ProfileUpdateFailure({required this.error});
}
