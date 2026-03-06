import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late PostCreate usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostCreate(postRepository: mockPostRepository);
  });

  setUpAll(() {
    registerFallbackValue(<PlatformFile>[]);
  });

  const tUser = User(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
  );

  final tPost = Post(
    id: 'post-123',
    user: tUser,
    content: 'Test post content',
    mediaUrls: ['https://example.com/image.jpg'],
    likeCount: 0,
    commentCount: 0,
    isLiked: false,
    createdAt: DateTime(2024, 1, 1),
  );

  group('PostCreate', () {
    const tContent = 'Test post content';
    final tMedia = <PlatformFile>[];

    test('should call createPost with correct params', () async {
      when(
        () => mockPostRepository.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenAnswer((_) async => Right(tPost));

      await usecase(content: tContent, media: tMedia);

      verify(
        () => mockPostRepository.createPost(content: tContent, media: tMedia),
      ).called(1);
    });

    test('should return Right<Post> on success', () async {
      when(
        () => mockPostRepository.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenAnswer((_) async => Right(tPost));

      final result = await usecase(content: tContent, media: tMedia);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (post) => expect(post.id, tPost.id),
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to create post');
      when(
        () => mockPostRepository.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(content: tContent, media: tMedia);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to create post'),
        (_) => fail('Expected Left'),
      );
    });

    test('should pass media files correctly', () async {
      final mockFile = MockPlatformFile();
      final tMediaWithFiles = [mockFile];

      when(
        () => mockPostRepository.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenAnswer((_) async => Right(tPost));

      await usecase(content: tContent, media: tMediaWithFiles);

      verify(
        () => mockPostRepository.createPost(
          content: tContent,
          media: tMediaWithFiles,
        ),
      ).called(1);
    });
  });
}
