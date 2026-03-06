import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/common/cubit/app_user_cubit.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/services/device_service.dart';
import 'package:conet_app/core/services/presence_service.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_current.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_logout.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_send_otp.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_signin_with_google.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_verify_otp.dart';
import 'package:conet_app/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserLogin extends Mock implements UserLogin {}

class MockUserSendOtp extends Mock implements UserSendOtp {}

class MockUserSigninWithGoogle extends Mock implements UserSigninWithGoogle {}

class MockUserVerifyOtp extends Mock implements UserVerifyOtp {}

class MockUserCurrent extends Mock implements UserCurrent {}

class MockUserAddDetails extends Mock implements UserAddDetails {}

class MockUserLogout extends Mock implements UserLogout {}

class MockAppUserCubit extends Mock implements AppUserCubit {}

class MockPresenceService extends Mock implements PresenceService {}

class MockDeviceService extends Mock implements DeviceService {}

void main() {
  late AuthBloc authBloc;
  late MockUserLogin mockUserLogin;
  late MockUserSendOtp mockUserSendOtp;
  late MockUserSigninWithGoogle mockUserSigninWithGoogle;
  late MockUserVerifyOtp mockUserVerifyOtp;
  late MockUserCurrent mockUserCurrent;
  late MockUserAddDetails mockUserAddDetails;
  late MockUserLogout mockUserLogout;
  late MockAppUserCubit mockAppUserCubit;
  late MockPresenceService mockPresenceService;
  late MockDeviceService mockDeviceService;

  const tUser = User(
    id: 'bloc-test-user-123',
    email: 'bloctest@example.com',
    firstName: 'Bloc',
    lastName: 'Test',
    username: 'bloctest',
    profilePicUrl: '',
    userRole: UserRole.user,
  );

  const tNewUser = User(
    id: 'new-user-456',
    email: 'newuser@example.com',
    firstName: 'New',
    lastName: 'User',
    username: '',
    profilePicUrl: '',
    userRole: UserRole.user,
  );

  setUp(() {
    mockUserLogin = MockUserLogin();
    mockUserSendOtp = MockUserSendOtp();
    mockUserSigninWithGoogle = MockUserSigninWithGoogle();
    mockUserVerifyOtp = MockUserVerifyOtp();
    mockUserCurrent = MockUserCurrent();
    mockUserAddDetails = MockUserAddDetails();
    mockUserLogout = MockUserLogout();
    mockAppUserCubit = MockAppUserCubit();
    mockPresenceService = MockPresenceService();
    mockDeviceService = MockDeviceService();

    when(() => mockAppUserCubit.updateUser(any())).thenReturn(null);
    when(() => mockPresenceService.dispose()).thenAnswer((_) async {});
    when(() => mockDeviceService.init()).thenAnswer((_) async {});
    when(
      () => mockDeviceService.removeCurrentDevice(),
    ).thenAnswer((_) async {});

    authBloc = AuthBloc(
      userLogin: mockUserLogin,
      userSendOtp: mockUserSendOtp,
      userSigninWithGoogle: mockUserSigninWithGoogle,
      userVerifyOtp: mockUserVerifyOtp,
      userCurrent: mockUserCurrent,
      userAddDetails: mockUserAddDetails,
      userLogout: mockUserLogout,
      appUserCubit: mockAppUserCubit,
      presenceService: mockPresenceService,
      deviceService: mockDeviceService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  test('initial state is AuthInitial', () {
    expect(authBloc.state, isA<AuthInitial>());
  });

  group('AuthLogin', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login succeeds',
      build: () {
        when(
          () => mockUserLogin(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogin(email: tEmail, password: tPassword)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.user, 'user', tUser),
      ],
      verify: (_) {
        verify(
          () => mockUserLogin(email: tEmail, password: tPassword),
        ).called(1);
        verify(() => mockAppUserCubit.updateUser(tUser)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when login fails',
      build: () {
        when(
          () => mockUserLogin(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Invalid credentials')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogin(email: tEmail, password: tPassword)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          'Invalid credentials',
        ),
      ],
    );
  });

  group('AuthSigninWithGoogle', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when Google sign-in succeeds',
      build: () {
        when(
          () => mockUserSigninWithGoogle(),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSigninWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.user, 'user', tUser),
      ],
      verify: (_) {
        verify(() => mockUserSigninWithGoogle()).called(1);
        verify(() => mockAppUserCubit.updateUser(tUser)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when Google sign-in fails',
      build: () {
        when(
          () => mockUserSigninWithGoogle(),
        ).thenAnswer((_) async => Left(AppFailure('Google sign-in cancelled')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSigninWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          'Google sign-in cancelled',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] with isNewUser true for new Google users',
      build: () {
        when(
          () => mockUserSigninWithGoogle(),
        ).thenAnswer((_) async => const Right(tNewUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthSigninWithGoogle()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>()
            .having((s) => s.user, 'user', tNewUser)
            .having((s) => s.isNewUser, 'isNewUser', true),
      ],
    );
  });

  group('AuthSendOtp', () {
    const tEmail = 'register@example.com';
    const tFirstName = 'Register';
    const tLastName = 'User';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOtpSentSuccess] when OTP sent successfully',
      build: () {
        when(
          () => mockUserSendOtp(
            email: any(named: 'email'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          ),
        ).thenAnswer((_) async => const Right(true));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        AuthSendOtp(email: tEmail, firstName: tFirstName, lastName: tLastName),
      ),
      expect: () => [isA<AuthLoading>(), isA<AuthOtpSentSuccess>()],
      verify: (_) {
        verify(
          () => mockUserSendOtp(
            email: tEmail,
            firstName: tFirstName,
            lastName: tLastName,
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when OTP fails to send',
      build: () {
        when(
          () => mockUserSendOtp(
            email: any(named: 'email'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Email already registered')));
        return authBloc;
      },
      act: (bloc) =>
          bloc.add(AuthSendOtp(email: tEmail, firstName: tFirstName)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          'Email already registered',
        ),
      ],
    );
  });

  group('AuthVerifyOtp', () {
    const tEmail = 'verify@example.com';
    const tOtp = '123456';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when OTP verified successfully',
      build: () {
        when(
          () => mockUserVerifyOtp(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
          ),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthVerifyOtp(email: tEmail, otp: tOtp)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.user, 'user', tUser),
      ],
      verify: (_) {
        verify(() => mockUserVerifyOtp(email: tEmail, otp: tOtp)).called(1);
        verify(() => mockAppUserCubit.updateUser(tUser)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when OTP verification fails',
      build: () {
        when(
          () => mockUserVerifyOtp(
            email: any(named: 'email'),
            otp: any(named: 'otp'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Invalid OTP')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthVerifyOtp(email: tEmail, otp: tOtp)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Invalid OTP'),
      ],
    );
  });

  group('AuthAddDetails', () {
    const tUsername = 'newusername';
    const tFirstName = 'Updated';
    const tLastName = 'Name';
    const tPassword = 'newpass123';

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when add details succeeds',
      build: () {
        when(
          () => mockUserAddDetails(
            username: any(named: 'username'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(
        AuthAddDetails(
          username: tUsername,
          firstName: tFirstName,
          lastName: tLastName,
          password: tPassword,
        ),
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.user, 'user', tUser),
      ],
      verify: (_) {
        verify(
          () => mockUserAddDetails(
            username: tUsername,
            firstName: tFirstName,
            lastName: tLastName,
            password: tPassword,
          ),
        ).called(1);
        verify(() => mockAppUserCubit.updateUser(tUser)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when add details fails',
      build: () {
        when(
          () => mockUserAddDetails(
            username: any(named: 'username'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Username already taken')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthAddDetails(username: tUsername)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          'Username already taken',
        ),
      ],
    );
  });

  group('AuthIsUserLoggedIn', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when user is logged in',
      build: () {
        when(
          () => mockUserCurrent(),
        ).thenAnswer((_) async => const Right(tUser));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthIsUserLoggedIn()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>().having((s) => s.user, 'user', tUser),
      ],
      verify: (_) {
        verify(() => mockUserCurrent()).called(1);
        verify(() => mockAppUserCubit.updateUser(tUser)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when user is not logged in',
      build: () {
        when(
          () => mockUserCurrent(),
        ).thenAnswer((_) async => Left(AppFailure('User not logged in!')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthIsUserLoggedIn()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having(
          (s) => s.message,
          'message',
          'User not logged in!',
        ),
      ],
    );
  });

  group('AuthLogout', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, call cubit logout] when logout succeeds',
      build: () {
        when(() => mockUserLogout()).thenAnswer((_) async => const Right(unit));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogout()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
      verify: (_) {
        verify(() => mockUserLogout()).called(1);
        verify(() => mockAppUserCubit.logout()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when logout fails',
      build: () {
        when(
          () => mockUserLogout(),
        ).thenAnswer((_) async => Left(AppFailure('Logout failed')));
        return authBloc;
      },
      act: (bloc) => bloc.add(AuthLogout()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthFailure>().having((s) => s.message, 'message', 'Logout failed'),
      ],
    );
  });
}
