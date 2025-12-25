import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_current.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UserCurrent usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UserCurrent(authRepository: mockAuthRepository);
  });

  const tUser = User(
    id: 'current-user-101',
    email: 'currentuser@example.com',
    firstName: 'Current',
    lastName: 'User',
    username: 'currentuser',
    profilePicUrl: 'https://example.com/avatar.png',
    userRole: UserRole.user,
    isVerified: true,
  );

  group('UserCurrent', () {
    test('should call currentUser on repository', () async {
      when(
        () => mockAuthRepository.currentUser(),
      ).thenAnswer((_) async => const Right(tUser));

      await usecase();

      verify(() => mockAuthRepository.currentUser()).called(1);
    });

    test('should return Right<User> on success', () async {
      when(
        () => mockAuthRepository.currentUser(),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await usecase();

      expect(result, const Right(tUser));
    });

    test('should return Left<AppFailure> when user not logged in', () async {
      final tFailure = AppFailure('User not logged in!');
      when(
        () => mockAuthRepository.currentUser(),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not logged in!'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
