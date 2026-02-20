import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/common/entities/social_links.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/profile/domain/entities/user_academics.dart';
import 'package:conet_app/feature/profile/domain/entities/user_profile.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_get_user.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_about_me.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_academic_info.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_interests.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_personal_info.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_pictures.dart';
import 'package:conet_app/feature/profile/domain/usecases/profile_update_social_links.dart';
import 'package:conet_app/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileGetUser extends Mock implements ProfileGetUser {}

class MockProfileUpdatePersonalInfo extends Mock
    implements ProfileUpdatePersonalInfo {}

class MockProfileUpdateAboutMe extends Mock implements ProfileUpdateAboutMe {}

class MockProfileUpdateInterests extends Mock
    implements ProfileUpdateInterests {}

class MockProfileUpdateAcademicInfo extends Mock
    implements ProfileUpdateAcademicInfo {}

class MockProfileUpdateSocialLinks extends Mock
    implements ProfileUpdateSocialLinks {}

class MockProfileUpdatePictures extends Mock implements ProfileUpdatePictures {}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late ProfileBloc profileBloc;
  late MockProfileGetUser mockGetUser;
  late MockProfileUpdatePersonalInfo mockUpdatePersonalInfo;
  late MockProfileUpdateAboutMe mockUpdateAboutMe;
  late MockProfileUpdateInterests mockUpdateInterests;
  late MockProfileUpdateAcademicInfo mockUpdateAcademicInfo;
  late MockProfileUpdateSocialLinks mockUpdateSocialLinks;
  late MockProfileUpdatePictures mockUpdatePictures;

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

  setUp(() {
    mockGetUser = MockProfileGetUser();
    mockUpdatePersonalInfo = MockProfileUpdatePersonalInfo();
    mockUpdateAboutMe = MockProfileUpdateAboutMe();
    mockUpdateInterests = MockProfileUpdateInterests();
    mockUpdateAcademicInfo = MockProfileUpdateAcademicInfo();
    mockUpdateSocialLinks = MockProfileUpdateSocialLinks();
    mockUpdatePictures = MockProfileUpdatePictures();

    profileBloc = ProfileBloc(
      getUser: mockGetUser,
      updatePersonalInfo: mockUpdatePersonalInfo,
      updateAboutMe: mockUpdateAboutMe,
      updateInterests: mockUpdateInterests,
      updateAcademicInfo: mockUpdateAcademicInfo,
      updateSocialLinks: mockUpdateSocialLinks,
      updatePictures: mockUpdatePictures,
    );
  });

  setUpAll(() {
    registerFallbackValue(<SocialLinks>[]);
    registerFallbackValue(MockPlatformFile());
  });

  tearDown(() {
    profileBloc.close();
  });

  test('initial state is ProfileInitial', () {
    expect(profileBloc.state, isA<ProfileInitial>());
  });

  group('ProfileGetEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] when getUser succeeds',
      build: () {
        when(
          () => mockGetUser(any()),
        ).thenAnswer((_) async => Right(tUserProfile));
        return profileBloc;
      },
      act: (bloc) => bloc.add(ProfileGetEvent(uid: 'user-123')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileLoaded>().having(
          (s) => s.userProfile.id,
          'userProfile.id',
          'user-123',
        ),
      ],
      verify: (_) {
        verify(() => mockGetUser('user-123')).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] when getUser fails',
      build: () {
        when(
          () => mockGetUser(any()),
        ).thenAnswer((_) async => Left(AppFailure('User not found')));
        return profileBloc;
      },
      act: (bloc) => bloc.add(ProfileGetEvent(uid: 'user-123')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'User not found',
        ),
      ],
    );
  });

  group('ProfileUpdatePersonalInfoEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateSuccess] on success',
      build: () {
        when(
          () => mockUpdatePersonalInfo(
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            dateOfBirth: any(named: 'dateOfBirth'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) => bloc.add(
        ProfileUpdatePersonalInfoEvent(firstName: 'John', lastName: 'Doe'),
      ),
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
      verify: (_) {
        verify(
          () => mockUpdatePersonalInfo(
            firstName: 'John',
            lastName: 'Doe',
            dateOfBirth: null,
          ),
        ).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] on failure',
      build: () {
        when(
          () => mockUpdatePersonalInfo(
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            dateOfBirth: any(named: 'dateOfBirth'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Update failed')));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdatePersonalInfoEvent(firstName: 'John')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'Update failed',
        ),
      ],
    );
  });

  group('ProfileUpdateAboutMeEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateSuccess] on success',
      build: () {
        when(
          () => mockUpdateAboutMe(any()),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdateAboutMeEvent(aboutMe: 'New about me')),
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
      verify: (_) {
        verify(() => mockUpdateAboutMe('New about me')).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] on failure',
      build: () {
        when(
          () => mockUpdateAboutMe(any()),
        ).thenAnswer((_) async => Left(AppFailure('Update failed')));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdateAboutMeEvent(aboutMe: 'New about me')),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'Update failed',
        ),
      ],
    );
  });

  group('ProfileUpdateInterestsEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateSuccess] on success',
      build: () {
        when(
          () => mockUpdateInterests(any()),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdateInterestsEvent(interests: ['Flutter', 'AI'])),
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
      verify: (_) {
        verify(() => mockUpdateInterests(['Flutter', 'AI'])).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] on failure',
      build: () {
        when(
          () => mockUpdateInterests(any()),
        ).thenAnswer((_) async => Left(AppFailure('Update failed')));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdateInterestsEvent(interests: ['Flutter'])),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'Update failed',
        ),
      ],
    );
  });

  group('ProfileUpdateAcademicInfoEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateSuccess] on success',
      build: () {
        when(
          () => mockUpdateAcademicInfo(
            collegeName: any(named: 'collegeName'),
            course: any(named: 'course'),
            major: any(named: 'major'),
            startYear: any(named: 'startYear'),
            endYear: any(named: 'endYear'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) => bloc.add(
        ProfileUpdateAcademicInfoEvent(
          collegeName: 'Test University',
          course: 'CS',
          major: 'AI',
          startYear: 2022,
          endYear: 2026,
        ),
      ),
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
      verify: (_) {
        verify(
          () => mockUpdateAcademicInfo(
            collegeName: 'Test University',
            course: 'CS',
            major: 'AI',
            startYear: 2022,
            endYear: 2026,
          ),
        ).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] on failure',
      build: () {
        when(
          () => mockUpdateAcademicInfo(
            collegeName: any(named: 'collegeName'),
            course: any(named: 'course'),
            major: any(named: 'major'),
            startYear: any(named: 'startYear'),
            endYear: any(named: 'endYear'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Update failed')));
        return profileBloc;
      },
      act: (bloc) => bloc.add(
        ProfileUpdateAcademicInfoEvent(collegeName: 'Test', course: 'CS'),
      ),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'Update failed',
        ),
      ],
    );
  });

  group('ProfileUpdateSocialLinksEvent', () {
    final tSocialLinks = [
      SocialLinks(name: 'github', link: 'https://github.com/test'),
    ];

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateSuccess] on success',
      build: () {
        when(
          () => mockUpdateSocialLinks(any()),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdateSocialLinksEvent(socialLinks: tSocialLinks)),
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
      verify: (_) {
        verify(() => mockUpdateSocialLinks(tSocialLinks)).called(1);
      },
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] on failure',
      build: () {
        when(
          () => mockUpdateSocialLinks(any()),
        ).thenAnswer((_) async => Left(AppFailure('Update failed')));
        return profileBloc;
      },
      act: (bloc) =>
          bloc.add(ProfileUpdateSocialLinksEvent(socialLinks: tSocialLinks)),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'Update failed',
        ),
      ],
    );
  });

  group('ProfileUpdatePicturesEvent', () {
    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateSuccess] on success',
      build: () {
        when(
          () => mockUpdatePictures(
            profilePic: any(named: 'profilePic'),
            bannerImage: any(named: 'bannerImage'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) => bloc.add(ProfileUpdatePicturesEvent()),
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileUpdateFailure] on failure',
      build: () {
        when(
          () => mockUpdatePictures(
            profilePic: any(named: 'profilePic'),
            bannerImage: any(named: 'bannerImage'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Upload failed')));
        return profileBloc;
      },
      act: (bloc) => bloc.add(ProfileUpdatePicturesEvent()),
      expect: () => [
        isA<ProfileLoading>(),
        isA<ProfileUpdateFailure>().having(
          (s) => s.error,
          'error',
          'Upload failed',
        ),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'passes profile pic and banner correctly',
      build: () {
        when(
          () => mockUpdatePictures(
            profilePic: any(named: 'profilePic'),
            bannerImage: any(named: 'bannerImage'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        return profileBloc;
      },
      act: (bloc) {
        final mockPic = MockPlatformFile();
        final mockBanner = MockPlatformFile();
        bloc.add(
          ProfileUpdatePicturesEvent(
            profilePic: mockPic,
            bannerImage: mockBanner,
          ),
        );
      },
      expect: () => [isA<ProfileLoading>(), isA<ProfileUpdateSuccess>()],
    );
  });
}
