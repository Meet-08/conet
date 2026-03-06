import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/auth/domain/repository/auth_repository.dart';
import 'package:conet_app/feature/auth/domain/usecases/user_signin_with_google.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late UserSigninWithGoogle usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = UserSigninWithGoogle(authRepository: mockAuthRepository);
  });

  const tUser = User(
    id: 'google-user-456',
    email: 'googleuser@gmail.com',
    firstName: 'Jane',
    lastName: 'Smith',
    username: 'janesmith',
    profilePicUrl: 'https://example.com/pic.jpg',
    userRole: UserRole.user,
  );

  group('UserSigninWithGoogle', () {
    test('should call signInWithGoogle on repository', () async {
      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const Right(tUser));

      await usecase();

      verify(() => mockAuthRepository.signInWithGoogle()).called(1);
    });

    test('should return Right<User> on success', () async {
      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const Right(tUser));

      final result = await usecase();

      expect(result, const Right(tUser));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Google sign-in cancelled');
      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Google sign-in cancelled'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
