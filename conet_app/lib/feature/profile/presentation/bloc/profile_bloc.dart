import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_follow_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_unfollow_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_about_me.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_academic_info.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_interests.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_personal_info.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_pictures.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_social_links.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileUpdatePersonalInfo _updatePersonalInfo;
  final ProfileUpdateAboutMe _updateAboutMe;
  final ProfileUpdateInterests _updateInterests;
  final ProfileUpdateAcademicInfo _updateAcademicInfo;
  final ProfileUpdateSocialLinks _updateSocialLinks;
  final ProfileUpdatePictures _updatePictures;
  final ProfileGetUser _getUser;
  final ProfileFollowUser _followUser;
  final ProfileUnfollowUser _unfollowUser;

  ProfileBloc({
    required ProfileUpdatePersonalInfo updatePersonalInfo,
    required ProfileUpdateAboutMe updateAboutMe,
    required ProfileUpdateInterests updateInterests,
    required ProfileUpdateAcademicInfo updateAcademicInfo,
    required ProfileUpdateSocialLinks updateSocialLinks,
    required ProfileUpdatePictures updatePictures,
    required ProfileGetUser getUser,
    required ProfileFollowUser followUser,
    required ProfileUnfollowUser unfollowUser,
  }) : _updatePersonalInfo = updatePersonalInfo,
       _updateAboutMe = updateAboutMe,
       _updateInterests = updateInterests,
       _updateAcademicInfo = updateAcademicInfo,
       _updateSocialLinks = updateSocialLinks,
       _updatePictures = updatePictures,
       _getUser = getUser,
       _followUser = followUser,
       _unfollowUser = unfollowUser,
       super(ProfileInitial()) {
    on<ProfileGetEvent>(_onGetProfile);
    on<ProfileUpdatePersonalInfoEvent>(_onUpdatePersonalInfo);
    on<ProfileUpdateAboutMeEvent>(_onUpdateAboutMe);
    on<ProfileUpdateInterestsEvent>(_onUpdateInterests);
    on<ProfileUpdateAcademicInfoEvent>(_onUpdateAcademicInfo);
    on<ProfileUpdateSocialLinksEvent>(_onUpdateSocialLinks);
    on<ProfileUpdatePicturesEvent>(_onUpdatePictures);
    on<ProfileFollowUserEvent>(_onFollowUser);
    on<ProfileUnfollowUserEvent>(_onUnfollowUser);
  }

  Future<void> _onGetProfile(
    ProfileGetEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _getUser(event.uid);
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (profile) => emit(ProfileLoaded(profile)),
    );
  }

  Future<void> _onUpdatePersonalInfo(
    ProfileUpdatePersonalInfoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updatePersonalInfo(
      firstName: event.firstName,
      lastName: event.lastName,
      dateOfBirth: event.dateOfBirth,
    );
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (_) => emit(ProfileUpdateSuccess()),
    );
  }

  Future<void> _onUpdateAboutMe(
    ProfileUpdateAboutMeEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updateAboutMe(event.aboutMe);
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (_) => emit(ProfileUpdateSuccess()),
    );
  }

  Future<void> _onUpdateInterests(
    ProfileUpdateInterestsEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updateInterests(event.interests);
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (_) => emit(ProfileUpdateSuccess()),
    );
  }

  Future<void> _onUpdateAcademicInfo(
    ProfileUpdateAcademicInfoEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updateAcademicInfo(
      collegeName: event.collegeName,
      course: event.course,
      degree: event.degree,
      startYear: event.startYear,
      endYear: event.endYear,
    );
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (_) => emit(ProfileUpdateSuccess()),
    );
  }

  Future<void> _onUpdateSocialLinks(
    ProfileUpdateSocialLinksEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updateSocialLinks(event.socialLinks);
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (_) => emit(ProfileUpdateSuccess()),
    );
  }

  Future<void> _onUpdatePictures(
    ProfileUpdatePicturesEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    final result = await _updatePictures(
      profilePic: event.profilePic,
      bannerImage: event.bannerImage,
    );
    result.fold(
      (failure) => emit(ProfileUpdateFailure(error: failure.message)),
      (_) => emit(ProfileUpdateSuccess()),
    );
  }

  Future<void> _onFollowUser(
    ProfileFollowUserEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      final result = await _followUser(event.targetUid);
      result.fold(
        (failure) => emit(ProfileUpdateFailure(error: failure.message)),
        (_) {},
      );
      return;
    }

    // Optimistic update
    final optimistic = currentState.userProfile.copyWith(
      isFollowing: true,
      followerCount: currentState.userProfile.followerCount + 1,
    );
    emit(ProfileLoaded(optimistic));

    final result = await _followUser(event.targetUid);
    result.fold((failure) {
      // Revert on failure
      emit(ProfileLoaded(currentState.userProfile));
      emit(
        ProfileFollowFailure(
          error: failure.message,
          profile: currentState.userProfile,
        ),
      );
    }, (_) {});
  }

  Future<void> _onUnfollowUser(
    ProfileUnfollowUserEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoaded) {
      final result = await _unfollowUser(event.targetUid);
      result.fold(
        (failure) => emit(ProfileUpdateFailure(error: failure.message)),
        (_) {},
      );
      return;
    }

    // Optimistic update
    final optimistic = currentState.userProfile.copyWith(
      isFollowing: false,
      followerCount: (currentState.userProfile.followerCount - 1).clamp(
        0,
        999999999,
      ),
    );
    emit(ProfileLoaded(optimistic));

    final result = await _unfollowUser(event.targetUid);
    result.fold((failure) {
      // Revert on failure
      emit(ProfileLoaded(currentState.userProfile));
      emit(
        ProfileFollowFailure(
          error: failure.message,
          profile: currentState.userProfile,
        ),
      );
    }, (_) {});
  }
}
