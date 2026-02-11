import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_academic_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ProfileUpdateAcademicInfo usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileUpdateAcademicInfo(repository: mockRepository);
  });

  group('ProfileUpdateAcademicInfo', () {
    test('should call updateAcademicInfo with correct params', () async {
      when(
        () => mockRepository.updateAcademicInfo(
          collegeName: any(named: 'collegeName'),
          course: any(named: 'course'),
          major: any(named: 'major'),
          startYear: any(named: 'startYear'),
          endYear: any(named: 'endYear'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(
        collegeName: 'Test University',
        course: 'Computer Science',
        major: 'AI',
        startYear: 2022,
        endYear: 2026,
      );

      verify(
        () => mockRepository.updateAcademicInfo(
          collegeName: 'Test University',
          course: 'Computer Science',
          major: 'AI',
          startYear: 2022,
          endYear: 2026,
        ),
      ).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockRepository.updateAcademicInfo(
          collegeName: any(named: 'collegeName'),
          course: any(named: 'course'),
          major: any(named: 'major'),
          startYear: any(named: 'startYear'),
          endYear: any(named: 'endYear'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(
        collegeName: 'Test University',
        course: 'CS',
      );

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to update academic info');
      when(
        () => mockRepository.updateAcademicInfo(
          collegeName: any(named: 'collegeName'),
          course: any(named: 'course'),
          major: any(named: 'major'),
          startYear: any(named: 'startYear'),
          endYear: any(named: 'endYear'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(collegeName: 'Test', course: 'CS');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update academic info'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle optional parameters as null', () async {
      when(
        () => mockRepository.updateAcademicInfo(
          collegeName: any(named: 'collegeName'),
          course: any(named: 'course'),
          major: any(named: 'major'),
          startYear: any(named: 'startYear'),
          endYear: any(named: 'endYear'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(
        collegeName: 'University',
        course: 'Engineering',
      );

      expect(result, const Right(unit));
      verify(
        () => mockRepository.updateAcademicInfo(
          collegeName: 'University',
          course: 'Engineering',
          major: null,
          startYear: null,
          endYear: null,
        ),
      ).called(1);
    });
  });
}
