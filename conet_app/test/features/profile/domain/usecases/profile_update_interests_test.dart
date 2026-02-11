import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_interests.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ProfileUpdateInterests usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileUpdateInterests(repository: mockRepository);
  });

  group('ProfileUpdateInterests', () {
    final tInterests = ['Flutter', 'Dart', 'Machine Learning'];

    test('should call updateInterests with correct list', () async {
      when(
        () => mockRepository.updateInterests(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tInterests);

      verify(() => mockRepository.updateInterests(tInterests)).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockRepository.updateInterests(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tInterests);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to update interests');
      when(
        () => mockRepository.updateInterests(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tInterests);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update interests'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle empty interests list', () async {
      when(
        () => mockRepository.updateInterests(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(<String>[]);

      expect(result, const Right(unit));
      verify(() => mockRepository.updateInterests(<String>[])).called(1);
    });
  });
}
