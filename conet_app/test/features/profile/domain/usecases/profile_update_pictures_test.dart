import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_pictures.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late ProfileUpdatePictures usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileUpdatePictures(repository: mockRepository);
  });

  setUpAll(() {
    registerFallbackValue(MockPlatformFile());
  });

  group('ProfileUpdatePictures', () {
    test('should call updatePictures with correct params', () async {
      final mockProfilePic = MockPlatformFile();
      final mockBanner = MockPlatformFile();

      when(
        () => mockRepository.updatePictures(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(profilePic: mockProfilePic, bannerImage: mockBanner);

      verify(
        () => mockRepository.updatePictures(mockProfilePic, mockBanner),
      ).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockRepository.updatePictures(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase();

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to upload pictures');
      when(
        () => mockRepository.updatePictures(any(), any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to upload pictures'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle only profile pic', () async {
      final mockProfilePic = MockPlatformFile();

      when(
        () => mockRepository.updatePictures(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(profilePic: mockProfilePic);

      expect(result, const Right(unit));
      verify(
        () => mockRepository.updatePictures(mockProfilePic, null),
      ).called(1);
    });

    test('should handle only banner image', () async {
      final mockBanner = MockPlatformFile();

      when(
        () => mockRepository.updatePictures(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(bannerImage: mockBanner);

      expect(result, const Right(unit));
      verify(() => mockRepository.updatePictures(null, mockBanner)).called(1);
    });
  });
}
