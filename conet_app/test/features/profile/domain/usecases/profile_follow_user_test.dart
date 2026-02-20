import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_follow_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ProfileFollowUser usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileFollowUser(repository: mockRepository);
  });

  const tTargetUid = 'target-user-456';

  group('ProfileFollowUser', () {
    test('should delegate to repository.followUser with correct uid', () async {
      when(
        () => mockRepository.followUser(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tTargetUid);

      verify(() => mockRepository.followUser(tTargetUid)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Right(unit) on success', () async {
      when(
        () => mockRepository.followUser(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tTargetUid);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (value) => expect(value, unit),
      );
    });

    test('should return Left<AppFailure> when repository fails', () async {
      final tFailure = AppFailure('Failed to follow user');
      when(
        () => mockRepository.followUser(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tTargetUid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to follow user'),
        (_) => fail('Expected Left'),
      );
    });

    test('should pass the exact uid to the repository', () async {
      const differentUid = 'completely-different-uuid-789';
      when(
        () => mockRepository.followUser(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(differentUid);

      verify(() => mockRepository.followUser(differentUid)).called(1);
      verifyNever(() => mockRepository.followUser(tTargetUid));
    });
  });
}
