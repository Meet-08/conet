import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_current.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_signin_with_google.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserLogin _userLogin;
  final UserSendOtp _userSendOtp;
  final UserSigninWithGoogle _userSigninWithGoogle;
  final UserVerifyOtp _userVerifyOtp;
  final UserCurrent _userCurrent;
  final UserAddDetails _userAddDetails;
  final AppUserCubit _appUserCubit;

  AuthBloc({
    required UserLogin userLogin,
    required UserSendOtp userSendOtp,
    required UserSigninWithGoogle userSigninWithGoogle,
    required UserVerifyOtp userVerifyOtp,
    required UserCurrent userCurrent,
    required UserAddDetails userAddDetails,
    required AppUserCubit appUserCubit,
  }) : _userLogin = userLogin,
       _userSendOtp = userSendOtp,
       _userSigninWithGoogle = userSigninWithGoogle,
       _userVerifyOtp = userVerifyOtp,
       _userCurrent = userCurrent,
       _userAddDetails = userAddDetails,
       _appUserCubit = appUserCubit,

       super(AuthInitial()) {
    on<AuthLogin>(_onAuthLogin);
    on<AuthSendOtp>(_onAuthSendOtp);
    on<AuthVerifyOtp>(_onAuthVerifyOtp);
    on<AuthSigninWithGoogle>(_onAuthSigninWithGoogle);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);
    on<AuthAddDetails>(_onAuthAddDetails);
  }

  void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final loginResult = await _userLogin(
      email: event.email,
      password: event.password,
    );

    loginResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthVerifyOtp(AuthVerifyOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final verifyResult = await _userVerifyOtp(
      email: event.email,
      otp: event.otp,
    );

    verifyResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthSendOtp(AuthSendOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final otpResult = await _userSendOtp(
      email: event.email,
      firstName: event.firstName,
      lastName: event.lastName,
    );

    otpResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (val) => emit(AuthOtpSentSuccess()),
    );
  }

  void _onAuthAddDetails(AuthAddDetails event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final addDetailsResult = await _userAddDetails(
      username: event.username,
      firstName: event.firstName,
      lastName: event.lastName,
      password: event.password,
    );

    addDetailsResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthSigninWithGoogle(
    AuthSigninWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _userSigninWithGoogle();
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _isUserLoggedIn(
    AuthIsUserLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final res = await _userCurrent();

    res.fold((l) {
      _appUserCubit.updateUser(null);
      emit(AuthFailure(l.message));
    }, (r) => _emitAuthSuccess(r, emit));
  }

  void _emitAuthSuccess(User user, Emitter<AuthState> emit) {
    _appUserCubit.updateUser(user);
    emit(AuthSuccess(user, isNewUser: user.username.isEmpty));
  }
}
