import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_liked_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostGetLikedPosts usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostGetLikedPosts(postRepository: mockPostRepository);
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
    likeCount: 10,
    commentCount: 5,
    isLiked: true,
    createdAt: DateTime(2024, 1, 1),
  );

  final tPostList = [tPost];

  group('PostGetLikedPosts', () {
    test('should call getLikedPosts with default pagination', () async {
      when(
        () => mockPostRepository.getLikedPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tPostList));

      await usecase();

      verify(
        () => mockPostRepository.getLikedPosts(page: 1, limit: 20),
      ).called(1);
    });

    test('should call getLikedPosts with custom pagination', () async {
      when(
        () => mockPostRepository.getLikedPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tPostList));

      await usecase(page: 3, limit: 10);

      verify(
        () => mockPostRepository.getLikedPosts(page: 3, limit: 10),
      ).called(1);
    });

    test('should return Right<List<Post>> on success', () async {
      when(
        () => mockPostRepository.getLikedPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tPostList));

      final result = await usecase();

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (posts) {
        expect(posts.length, 1);
        expect(posts.first.id, tPost.id);
        expect(posts.first.isLiked, true);
      });
    });

    test('should return Right with empty list when no liked posts', () async {
      when(
        () => mockPostRepository.getLikedPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => const Right(<Post>[]));

      final result = await usecase();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (posts) => expect(posts.isEmpty, true),
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to fetch liked posts');
      when(
        () => mockPostRepository.getLikedPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch liked posts'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when network error occurs', () async {
      final tFailure = AppFailure('Network error');
      when(
        () => mockPostRepository.getLikedPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Network error'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
