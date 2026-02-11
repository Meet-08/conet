import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/auth/data/model/user_model.dart';
import 'package:conet_app/feature/profile/data/data_sources/profile_data_source.dart';
import 'package:conet_app/feature/profile/data/repositories/user_profile_repository_impl.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileDataSource extends Mock implements ProfileDataSource {}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late UserProfileRepositoryImpl repository;
  late MockProfileDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockProfileDataSource();
    repository = UserProfileRepositoryImpl(profileDataSource: mockDataSource);
  });

  setUpAll(() {
    registerFallbackValue(<SocialLinks>[]);
    registerFallbackValue(MockPlatformFile());
  });

  const tUserModel = UserModel(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  final tUserProfile = UserProfile(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    aboutMe: 'Test about me',
    profilePicUrl: 'https://example.com/pic.jpg',
    bannerImageUrl: 'https://example.com/banner.jpg',
    interests: const ['Flutter', 'Dart'],
    isVerified: true,
    socialLinks: const [],
    academics: [
      UserAcademics(
        id: 'acad-1',
        userId: 'user-123',
        collegeName: 'Test University',
        course: 'Computer Science',
        major: 'AI',
        startYear: 2022,
        endYear: 2026,
        createdAt: DateTime(2024, 1, 1),
      ),
    ],
    followerCount: 100,
    followingCount: 50,
  );

  group('getUserProfile', () {
    const tUid = 'user-123';

    test('should return Right<UserProfile> on success', () async {
      when(
        () => mockDataSource.getUserProfile(any()),
      ).thenAnswer((_) async => tUserProfile);

      final result = await repository.getUserProfile(tUid);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (profile) {
        expect(profile.id, tUserProfile.id);
        expect(profile.firstName, tUserProfile.firstName);
      });
      verify(() => mockDataSource.getUserProfile(tUid)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.getUserProfile(any()),
      ).thenThrow(ServerException('User not found'));

      final result = await repository.getUserProfile(tUid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not found'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when generic exception is thrown', () async {
      when(
        () => mockDataSource.getUserProfile(any()),
      ).thenThrow(Exception('Unexpected error'));

      final result = await repository.getUserProfile(tUid);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message.contains('Exception'), true),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updatePersonalInfo', () {
    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.updatePersonalInfo(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          dateOfBirth: any(named: 'dateOfBirth'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.updatePersonalInfo(
        'John',
        'Doe',
        DateTime(2000, 1, 1),
      );

      expect(result.isRight(), true);
      verify(
        () => mockDataSource.updatePersonalInfo(
          firstName: 'John',
          lastName: 'Doe',
          dateOfBirth: DateTime(2000, 1, 1),
        ),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.updatePersonalInfo(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          dateOfBirth: any(named: 'dateOfBirth'),
        ),
      ).thenThrow(ServerException('Failed to update'));

      final result = await repository.updatePersonalInfo('John', 'Doe', null);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updateAboutMe', () {
    const tAboutMe = 'New about me text';

    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.updateAboutMe(any()),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.updateAboutMe(tAboutMe);

      expect(result.isRight(), true);
      verify(() => mockDataSource.updateAboutMe(tAboutMe)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.updateAboutMe(any()),
      ).thenThrow(ServerException('Failed to update about me'));

      final result = await repository.updateAboutMe(tAboutMe);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update about me'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updateInterests', () {
    final tInterests = ['Flutter', 'Dart', 'AI'];

    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.updateInterests(any()),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.updateInterests(tInterests);

      expect(result.isRight(), true);
      verify(() => mockDataSource.updateInterests(tInterests)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.updateInterests(any()),
      ).thenThrow(ServerException('Failed to update interests'));

      final result = await repository.updateInterests(tInterests);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update interests'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updateAcademicInfo', () {
    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.updateAcademicInfo(
          collegeName: any(named: 'collegeName'),
          course: any(named: 'course'),
          major: any(named: 'major'),
          startYear: any(named: 'startYear'),
          endYear: any(named: 'endYear'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.updateAcademicInfo(
        collegeName: 'Test University',
        course: 'Computer Science',
        major: 'AI',
        startYear: 2022,
        endYear: 2026,
      );

      expect(result.isRight(), true);
      verify(
        () => mockDataSource.updateAcademicInfo(
          collegeName: 'Test University',
          course: 'Computer Science',
          major: 'AI',
          startYear: 2022,
          endYear: 2026,
        ),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.updateAcademicInfo(
          collegeName: any(named: 'collegeName'),
          course: any(named: 'course'),
          major: any(named: 'major'),
          startYear: any(named: 'startYear'),
          endYear: any(named: 'endYear'),
        ),
      ).thenThrow(ServerException('Failed to update academic info'));

      final result = await repository.updateAcademicInfo(
        collegeName: 'Test',
        course: 'CS',
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update academic info'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updateSocialLinks', () {
    final tSocialLinks = [
      SocialLinks(name: 'github', link: 'https://github.com/test'),
      SocialLinks(name: 'linkedin', link: 'https://linkedin.com/in/test'),
    ];

    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.updateSocialLinks(any()),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.updateSocialLinks(tSocialLinks);

      expect(result.isRight(), true);
      verify(() => mockDataSource.updateSocialLinks(tSocialLinks)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.updateSocialLinks(any()),
      ).thenThrow(ServerException('Failed to update social links'));

      final result = await repository.updateSocialLinks(tSocialLinks);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to update social links'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('updatePictures', () {
    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.updatePictures(
          profilePic: any(named: 'profilePic'),
          bannerImage: any(named: 'bannerImage'),
        ),
      ).thenAnswer((_) async => tUserModel);

      final result = await repository.updatePictures(null, null);

      expect(result.isRight(), true);
      verify(
        () =>
            mockDataSource.updatePictures(profilePic: null, bannerImage: null),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.updatePictures(
          profilePic: any(named: 'profilePic'),
          bannerImage: any(named: 'bannerImage'),
        ),
      ).thenThrow(ServerException('Failed to upload pictures'));

      final result = await repository.updatePictures(null, null);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to upload pictures'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
