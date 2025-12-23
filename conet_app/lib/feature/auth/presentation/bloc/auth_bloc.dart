import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
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
  final AppUserCubit _appUserCubit;

  AuthBloc({
    required UserLogin userLogin,
    required UserSendOtp userSendOtp,
    required UserSigninWithGoogle userSigninWithGoogle,
    required UserVerifyOtp userVerifyOtp,
    required AppUserCubit appUserCubit,
  }) : _userLogin = userLogin,
       _userSendOtp = userSendOtp,
       _userSigninWithGoogle = userSigninWithGoogle,
       _userVerifyOtp = userVerifyOtp,
       _appUserCubit = appUserCubit,
       super(AuthInitial()) {
    on<AuthEvent>((event, emit) => emit(AuthLoading()));
    on<AuthLogin>(_onAuthLogin);
    on<AuthSendOtp>(_onAuthSendOtp);
    on<AuthVerifyOtp>(_onAuthVerifyOtp);
    on<AuthSigninWithGoogle>(_onAuthSigninWithGoogle);
  }

  void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
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

  void _onAuthSigninWithGoogle(
    AuthSigninWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _userSigninWithGoogle();
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _emitAuthSuccess(User user, Emitter<AuthState> emit) {
    _appUserCubit.updateUser(user);
    emit(AuthSuccess(user));
  }
}
