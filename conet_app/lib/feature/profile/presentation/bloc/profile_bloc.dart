import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_user.dart';
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

  ProfileBloc({
    required ProfileUpdatePersonalInfo updatePersonalInfo,
    required ProfileUpdateAboutMe updateAboutMe,
    required ProfileUpdateInterests updateInterests,
    required ProfileUpdateAcademicInfo updateAcademicInfo,
    required ProfileUpdateSocialLinks updateSocialLinks,
    required ProfileUpdatePictures updatePictures,
    required ProfileGetUser getUser,
  }) : _updatePersonalInfo = updatePersonalInfo,
       _updateAboutMe = updateAboutMe,
       _updateInterests = updateInterests,
       _updateAcademicInfo = updateAcademicInfo,
       _updateSocialLinks = updateSocialLinks,
       _updatePictures = updatePictures,
       _getUser = getUser,
       super(ProfileInitial()) {
    on<ProfileGetEvent>(_onGetProfile);
    on<ProfileUpdatePersonalInfoEvent>(_onUpdatePersonalInfo);
    on<ProfileUpdateAboutMeEvent>(_onUpdateAboutMe);
    on<ProfileUpdateInterestsEvent>(_onUpdateInterests);
    on<ProfileUpdateAcademicInfoEvent>(_onUpdateAcademicInfo);
    on<ProfileUpdateSocialLinksEvent>(_onUpdateSocialLinks);
    on<ProfileUpdatePicturesEvent>(_onUpdatePictures);
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
      major: event.major,
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
}
