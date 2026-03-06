import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_user_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostGetUserPosts usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostGetUserPosts(postRepository: mockPostRepository);
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
    isLiked: false,
    createdAt: DateTime(2024, 1, 1),
  );

  final tPostList = [tPost];

  group('PostGetUserPosts', () {
    const tUserId = 'user-123';

    test(
      'should call getUserPosts with correct userId and default pagination',
      () async {
        when(
          () => mockPostRepository.getUserPosts(
            userId: any(named: 'userId'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Right(tPostList));

        await usecase(userId: tUserId);

        verify(
          () => mockPostRepository.getUserPosts(
            userId: tUserId,
            page: 1,
            limit: 20,
          ),
        ).called(1);
      },
    );

    test('should call getUserPosts with custom pagination', () async {
      when(
        () => mockPostRepository.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tPostList));

      await usecase(userId: tUserId, page: 2, limit: 15);

      verify(
        () => mockPostRepository.getUserPosts(
          userId: tUserId,
          page: 2,
          limit: 15,
        ),
      ).called(1);
    });

    test('should return Right<List<Post>> on success', () async {
      when(
        () => mockPostRepository.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Right(tPostList));

      final result = await usecase(userId: tUserId);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (posts) {
        expect(posts.length, 1);
        expect(posts.first.user.id, tUserId);
      });
    });

    test(
      'should return Right with empty list when user has no posts',
      () async {
        when(
          () => mockPostRepository.getUserPosts(
            userId: any(named: 'userId'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<Post>[]));

        final result = await usecase(userId: tUserId);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) => expect(posts.isEmpty, true),
        );
      },
    );

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to fetch user posts');
      when(
        () => mockPostRepository.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(userId: tUserId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch user posts'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when user not found', () async {
      final tFailure = AppFailure('User not found');
      when(
        () => mockPostRepository.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(userId: 'nonexistent-user');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not found'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
