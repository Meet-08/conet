import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UserLogin usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UserLogin(authRepository: mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  const tUser = User(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
  );

  group('UserLogin', () {
    test('should call loginWithEmailPassword with correct params', () async {
      when(
        () => mockAuthRepository.loginWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      await usecase(email: tEmail, password: tPassword);

      verify(
        () => mockAuthRepository.loginWithEmailPassword(
          email: tEmail,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should return Right<User> on success', () async {
      when(
        () => mockAuthRepository.loginWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await usecase(email: tEmail, password: tPassword);

      expect(result, const Right(tUser));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Invalid credentials');
      when(
        () => mockAuthRepository.loginWithEmailPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(email: tEmail, password: tPassword);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Invalid credentials'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
