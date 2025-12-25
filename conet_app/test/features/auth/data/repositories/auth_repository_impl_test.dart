import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/data_source/auth_data_source.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/feature/auth/data/repository/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class MockAuthDataSource extends Mock implements AuthDataSource {}

class MockSession extends Mock implements Session {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockAuthDataSource();
    repository = AuthRepositoryImpl(authDataSource: mockDataSource);
  });

  const tUserModel = UserModel(
    id: 'test-id-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  group('currentUser', () {
    test('should return Left when session is null', () async {
      when(() => mockDataSource.currentUserSession).thenReturn(null);

      final result = await repository.currentUser();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not logged in!'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when user data is null', () async {
      final mockSession = MockSession();
      when(() => mockDataSource.currentUserSession).thenReturn(mockSession);
      when(() => mockDataSource.currentUser()).thenAnswer((_) async => null);

      final result = await repository.currentUser();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User data not found!'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Right<User> when session and user exist', () async {
      final mockSession = MockSession();
      when(() => mockDataSource.currentUserSession).thenReturn(mockSession);
      when(
        () => mockDataSource.currentUser(),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.currentUser();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) => expect(user.id, tUserModel.id),
      );
    });

    test('should return Left when ServerException is thrown', () async {
      final mockSession = MockSession();
      when(() => mockDataSource.currentUserSession).thenReturn(mockSession);
      when(
        () => mockDataSource.currentUser(),
      ).thenThrow(ServerException('Server error'));

      final result = await repository.currentUser();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Server error'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('signInWithGoogle', () {
    test('should return Right<User> on success', () async {
      when(
        () => mockDataSource.signInWithGoogle(),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.signInWithGoogle();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) => expect(user.id, tUserModel.id),
      );
      verify(() => mockDataSource.signInWithGoogle()).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.signInWithGoogle(),
      ).thenThrow(ServerException('Google sign-in failed'));

      final result = await repository.signInWithGoogle();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Google sign-in failed'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('loginWithEmailPassword', () {
    const tEmail = 'test@example.com';
    const tPassword = 'password123';

    test('should return Right<User> on success', () async {
      when(
        () => mockDataSource.loginWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.loginWithEmailPassword(
        email: tEmail,
        password: tPassword,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) => expect(user.id, tUserModel.id),
      );
      verify(
        () => mockDataSource.loginWithEmailPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.loginWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(ServerException('Invalid credentials'));

      final result = await repository.loginWithEmailPassword(
        email: tEmail,
        password: tPassword,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Invalid credentials'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('verifyOtp', () {
    const tEmail = 'user@example.com';
    const tToken = '123456';

    test('should return Right<User> on success', () async {
      when(
        () => mockDataSource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.verifyOtp(email: tEmail, token: tToken);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) => expect(user.id, tUserModel.id),
      );
      verify(
        () => mockDataSource.verifyOtp(email: tEmail, token: tToken),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.verifyOtp(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(ServerException('Invalid OTP'));

      final result = await repository.verifyOtp(email: tEmail, token: tToken);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Invalid OTP'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('addDetails', () {
    const tUsername = 'newusername';
    const tFirstName = 'Updated';
    const tLastName = 'Name';
    const tPassword = 'newpass123';

    test('should return Right<User> on success', () async {
      when(
        () => mockDataSource.addDetails(
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.addDetails(
        username: tUsername,
        firstName: tFirstName,
        lastName: tLastName,
        password: tPassword,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (user) => expect(user.id, tUserModel.id),
      );
      verify(
        () => mockDataSource.addDetails(
          username: tUsername,
          firstName: tFirstName,
          lastName: tLastName,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.addDetails(
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          password: any(named: 'password'),
        ),
      ).thenThrow(ServerException('Username taken'));

      final result = await repository.addDetails(username: tUsername);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Username taken'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('sendOtp', () {
    const tEmail = 'new@example.com';
    const tFirstName = 'New';
    const tLastName = 'User';

    test('should return Right<bool> on success', () async {
      when(
        () => mockDataSource.sendOtp(
          email: any(named: 'email'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenAnswer((_) async => true);

      final result = await repository.sendOtp(
        email: tEmail,
        firstName: tFirstName,
        lastName: tLastName,
      );

      expect(result, const Right<AppFailure, bool>(true));
      verify(
        () => mockDataSource.sendOtp(
          email: tEmail,
          firstName: tFirstName,
          lastName: tLastName,
        ),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.sendOtp(
          email: any(named: 'email'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
        ),
      ).thenThrow(ServerException('Failed to send OTP'));

      final result = await repository.sendOtp(
        email: tEmail,
        firstName: tFirstName,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to send OTP'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
