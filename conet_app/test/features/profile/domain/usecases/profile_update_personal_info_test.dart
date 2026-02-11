import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_personal_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ProfileUpdatePersonalInfo usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileUpdatePersonalInfo(repository: mockRepository);
  });

  group('ProfileUpdatePersonalInfo', () {
    test('should call updatePersonalInfo with correct params', () async {
      when(
        () => mockRepository.updatePersonalInfo(any(), any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: DateTime(2000, 1, 1),
      );

      verify(
        () => mockRepository.updatePersonalInfo(
          'John',
          'Doe',
          DateTime(2000, 1, 1),
        ),
      ).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockRepository.updatePersonalInfo(any(), any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(firstName: 'John', lastName: 'Doe');

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to update personal info');
      when(
        () => mockRepository.updatePersonalInfo(any(), any(), any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(firstName: 'John');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update personal info'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle null parameters', () async {
      when(
        () => mockRepository.updatePersonalInfo(any(), any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase();

      expect(result, const Right(unit));
      verify(
        () => mockRepository.updatePersonalInfo(null, null, null),
      ).called(1);
    });
  });
}
