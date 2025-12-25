import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_add_details.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UserAddDetails usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UserAddDetails(authRepository: mockAuthRepository);
  });

  const tUsername = 'newusername';
  const tFirstName = 'Updated';
  const tLastName = 'Name';
  const tPassword = 'newpassword123';
  const tUser = User(
    id: 'user-add-details-202',
    email: 'details@example.com',
    firstName: 'Updated',
    lastName: 'Name',
    username: 'newusername',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  group('UserAddDetails', () {
    test('should call addDetails with all params', () async {
      when(
        () => mockAuthRepository.addDetails(
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      await usecase(
        username: tUsername,
        firstName: tFirstName,
        lastName: tLastName,
        password: tPassword,
      );

      verify(
        () => mockAuthRepository.addDetails(
          username: tUsername,
          firstName: tFirstName,
          lastName: tLastName,
          password: tPassword,
        ),
      ).called(1);
    });

    test('should call addDetails with only required username', () async {
      when(
        () => mockAuthRepository.addDetails(
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      await usecase(username: tUsername);

      verify(
        () => mockAuthRepository.addDetails(
          username: tUsername,
          firstName: null,
          lastName: null,
          password: null,
        ),
      ).called(1);
    });

    test('should return Right<User> on success', () async {
      when(
        () => mockAuthRepository.addDetails(
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await usecase(username: tUsername);

      expect(result, const Right(tUser));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Username already taken');
      when(
        () => mockAuthRepository.addDetails(
          username: any(named: 'username'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(username: tUsername);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Username already taken'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
