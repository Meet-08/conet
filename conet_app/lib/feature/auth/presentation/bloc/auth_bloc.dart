import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/router/app_router.dart';
import 'package:conet_app/core/services/device_service.dart';
import 'package:conet_app/core/services/presence_service.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_current.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_logout.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_signin_with_google.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_academic_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  static const _authTimeout = Duration(seconds: 30);

  final UserLogin _userLogin;
  final UserSendOtp _userSendOtp;
  final UserSigninWithGoogle _userSigninWithGoogle;
  final UserVerifyOtp _userVerifyOtp;
  final UserCurrent _userCurrent;
  final UserAddDetails _userAddDetails;
  final ProfileUpdateAcademicInfo _updateAcademicInfo;
  final UserLogout _userLogout;
  final AppUserCubit _appUserCubit;
  final PresenceService _presenceService;
  final DeviceService _deviceService;
  final void Function(String) _goToRoute;

  AuthBloc({
    required UserLogin userLogin,
    required UserSendOtp userSendOtp,
    required UserSigninWithGoogle userSigninWithGoogle,
    required UserVerifyOtp userVerifyOtp,
    required UserCurrent userCurrent,
    required UserAddDetails userAddDetails,
    required ProfileUpdateAcademicInfo updateAcademicInfo,
    required UserLogout userLogout,
    required AppUserCubit appUserCubit,
    required PresenceService presenceService,
    required DeviceService deviceService,
    void Function(String)? goToRoute,
  }) : _userLogin = userLogin,
       _userSendOtp = userSendOtp,
       _userSigninWithGoogle = userSigninWithGoogle,
       _userVerifyOtp = userVerifyOtp,
       _userCurrent = userCurrent,
       _userAddDetails = userAddDetails,
       _updateAcademicInfo = updateAcademicInfo,
       _userLogout = userLogout,
       _appUserCubit = appUserCubit,
       _presenceService = presenceService,
       _deviceService = deviceService,
       _goToRoute = goToRoute ?? ((path) => AppRouter.router.go(path)),

       super(AuthInitial()) {
    on<AuthLogin>(_onAuthLogin);
    on<AuthSendOtp>(_onAuthSendOtp);
    on<AuthVerifyOtp>(_onAuthVerifyOtp);
    on<AuthSigninWithGoogle>(_onAuthSigninWithGoogle);
    on<AuthIsUserLoggedIn>(_isUserLoggedIn);

    on<AuthAddDetails>(_onAuthAddDetails);
    on<AuthLogout>(_onAuthLogout);
  }

  void _onAuthLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(AuthLoadingAction.logout));
    final res = await _withAuthTimeout<Unit>(() async {
      _presenceService.dispose();
      await _deviceService.removeCurrentDevice();
      return _userLogout();
    });
    res.fold((l) => emit(AuthFailure(l.message)), (r) {
      _appUserCubit.logout();
      emit(AuthInitial());
      _goToRoute('/');
    });
  }

  void _onAuthLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(AuthLoadingAction.login));
    final loginResult = await _withAuthTimeout<User>(
      () => _userLogin(email: event.email, password: event.password),
    );

    loginResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthVerifyOtp(AuthVerifyOtp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(AuthLoadingAction.verifyOtp));
    final verifyResult = await _withAuthTimeout<User>(
      () => _userVerifyOtp(email: event.email, otp: event.otp),
    );

    verifyResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthSendOtp(AuthSendOtp event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(AuthLoadingAction.sendOtp));
    final otpResult = await _withAuthTimeout<bool>(
      () => _userSendOtp(
        email: event.email,
        firstName: event.firstName,
        lastName: event.lastName,
      ),
    );

    otpResult.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (val) => emit(AuthOtpSentSuccess()),
    );
  }

  void _onAuthAddDetails(AuthAddDetails event, Emitter<AuthState> emit) async {
    emit(const AuthLoading(AuthLoadingAction.addDetails));
    final addDetailsResult = await _withAuthTimeout<User>(
      () => _userAddDetails(
        username: event.username,
        firstName: event.firstName,
        lastName: event.lastName,
        password: event.password,
      ),
    );

    await addDetailsResult.fold(
      (failure) async {
        emit(AuthFailure(failure.message));
      },
      (user) async {
        final updateAcademicResult = await _updateAcademicInfo(
          collegeName: event.collegeName,
          degree: event.degree,
          course: event.course,
          startYear: event.startYear,
          endYear: event.endYear,
        );

        updateAcademicResult.fold(
          (failure) => emit(AuthFailure(failure.message)),
          (_) => _emitAuthSuccess(user, emit),
        );
      },
    );
  }

  void _onAuthSigninWithGoogle(
    AuthSigninWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingAction.googleSignIn));
    final result = await _withAuthTimeout<User>(
      () => _userSigninWithGoogle(),
    );
    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _isUserLoggedIn(
    AuthIsUserLoggedIn event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(AuthLoadingAction.currentUser));
    final res = await _withAuthTimeout<User>(() => _userCurrent());

    res.fold((l) {
      _appUserCubit.updateUser(null);
      emit(AuthFailure(l.message));
    }, (r) => _emitAuthSuccess(r, emit));
  }

  void _emitAuthSuccess(User user, Emitter<AuthState> emit) {
    _appUserCubit.updateUser(user);
    _presenceService.start(user.id);
    _deviceService.init();
    emit(AuthSuccess(user, isNewUser: user.username.isEmpty));
  }

  Future<Either<AppFailure, T>> _withAuthTimeout<T>(
    Future<Either<AppFailure, T>> Function() operation,
  ) {
    final future = operation().then<Either<AppFailure, T>>((result) => result);

    return future.timeout(
      _authTimeout,
      onTimeout: () {
        return left<AppFailure, T>(
          AppFailure(
            'This is taking longer than expected. Please check your connection and try again.',
          ),
        );
      },
    );
  }
}
