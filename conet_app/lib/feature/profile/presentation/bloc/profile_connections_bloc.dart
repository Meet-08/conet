import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_followers.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_following.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_connections_event.dart';
part 'profile_connections_state.dart';

class ProfileConnectionsBloc
    extends Bloc<ProfileConnectionsEvent, ProfileConnectionsState> {
  final ProfileGetFollowers _getFollowers;
  final ProfileGetFollowing _getFollowing;

  ProfileConnectionsBloc({
    required ProfileGetFollowers getFollowers,
    required ProfileGetFollowing getFollowing,
  }) : _getFollowers = getFollowers,
       _getFollowing = getFollowing,
       super(ProfileConnectionsInitial()) {
    on<ProfileConnectionsLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    ProfileConnectionsLoadRequested event,
    Emitter<ProfileConnectionsState> emit,
  ) async {
    emit(ProfileConnectionsLoading());

    final followersResult = await _getFollowers(event.uid);
    final followingResult = await _getFollowing(event.uid);

    String? failureMessage;
    List<User> followers = const [];
    List<User> following = const [];

    followersResult.fold(
      (failure) => failureMessage = failure.message,
      (users) => followers = users,
    );

    followingResult.fold(
      (failure) => failureMessage ??= failure.message,
      (users) => following = users,
    );

    if (failureMessage != null) {
      emit(ProfileConnectionsFailure(error: failureMessage!));
      return;
    }

    emit(ProfileConnectionsLoaded(followers: followers, following: following));
  }
}
