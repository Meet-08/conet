import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_social_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late ProfileUpdateSocialLinks usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileUpdateSocialLinks(repository: mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(<SocialLinks>[]);
  });

  group('ProfileUpdateSocialLinks', () {
    final tSocialLinks = [
      SocialLinks(name: 'github', link: 'https://github.com/test'),
      SocialLinks(name: 'linkedin', link: 'https://linkedin.com/in/test'),
    ];

    test('should call updateSocialLinks with correct list', () async {
      when(
        () => mockRepository.updateSocialLinks(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tSocialLinks);

      verify(() => mockRepository.updateSocialLinks(tSocialLinks)).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockRepository.updateSocialLinks(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tSocialLinks);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to update social links');
      when(
        () => mockRepository.updateSocialLinks(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tSocialLinks);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update social links'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle empty social links list', () async {
      when(
        () => mockRepository.updateSocialLinks(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(<SocialLinks>[]);

      expect(result, const Right(unit));
    });
  });
}
