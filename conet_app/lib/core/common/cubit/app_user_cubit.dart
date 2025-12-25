import 'package:conet_app/core/common/entities/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_user_state.dart';

class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserUnknown());

  bool get isLoggedIn => state is AppUserAuthenticated;
  bool get isUnknown => state is AppUserUnknown;

  void updateUser(User? user) {
    if (user == null) {
      emit(AppUserUnauthenticated());
    } else {
      emit(AppUserAuthenticated(user));
    }
  }
}
