import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_about_me.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ProfileUpdateAboutMe usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileUpdateAboutMe(repository: mockRepository);
  });

  group('ProfileUpdateAboutMe', () {
    const tAboutMe = 'Passionate developer building cool things!';

    test('should call updateAboutMe with correct text', () async {
      when(
        () => mockRepository.updateAboutMe(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tAboutMe);

      verify(() => mockRepository.updateAboutMe(tAboutMe)).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockRepository.updateAboutMe(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tAboutMe);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to update about me');
      when(
        () => mockRepository.updateAboutMe(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tAboutMe);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update about me'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle empty about me text', () async {
      when(
        () => mockRepository.updateAboutMe(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase('');

      expect(result, const Right(unit));
      verify(() => mockRepository.updateAboutMe('')).called(1);
    });

    test('should handle special characters', () async {
      const specialText = 'About me with émojis 🚀 and spëcial çharacters!';
      when(
        () => mockRepository.updateAboutMe(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(specialText);

      expect(result, const Right(unit));
    });
  });
}
