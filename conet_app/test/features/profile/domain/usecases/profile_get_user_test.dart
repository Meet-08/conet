import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/domain/repositories/user_profile_repository.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

void main() {
  late ProfileGetUser usecase;
  late MockUserProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockUserProfileRepository();
    usecase = ProfileGetUser(userProfileRepository: mockRepository);
  });

  final tUserProfile = UserProfile(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    aboutMe: 'Test about me',
    profilePicUrl: 'https://example.com/pic.jpg',
    bannerImageUrl: null,
    interests: const ['Flutter', 'Dart'],
    isVerified: true,
    socialLinks: const [],
    academics: [
      UserAcademics(
        id: 'acad-1',
        userId: 'user-123',
        collegeName: 'Test University',
        course: 'Computer Science',
        createdAt: DateTime(2024, 1, 1),
      ),
    ],
    followerCount: 100,
    followingCount: 50,
  );

  group('ProfileGetUser', () {
    const tUid = 'user-123';

    test('should call getUserProfile with correct uid', () async {
      when(
        () => mockRepository.getUserProfile(any()),
      ).thenAnswer((_) async => Right(tUserProfile));

      await usecase(tUid);

      verify(() => mockRepository.getUserProfile(tUid)).called(1);
    });

    test('should return Right<UserProfile> on success', () async {
      when(
        () => mockRepository.getUserProfile(any()),
      ).thenAnswer((_) async => Right(tUserProfile));

      final result = await usecase(tUid);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (profile) {
          expect(profile.id, tUserProfile.id);
          expect(profile.firstName, 'John');
          expect(profile.interests, ['Flutter', 'Dart']);
        },
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('User not found');
      when(
        () => mockRepository.getUserProfile(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tUid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not found'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when network error occurs', () async {
      final tFailure = AppFailure('Network error');
      when(
        () => mockRepository.getUserProfile(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tUid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Network error'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
