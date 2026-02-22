import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/post_bookmark_local_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/data/models/comment_model.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:conet_app/feature/post/data/repositories/post_repository_impl.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostDataSource extends Mock implements PostDataSource {}

class MockPostBookmarkLocalDataSource extends Mock
    implements PostBookmarkLocalDataSource {}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late PostRepositoryImpl repository;
  late MockPostDataSource mockDataSource;
  late MockPostBookmarkLocalDataSource mockBookmarkDataSource;

  setUp(() {
    mockDataSource = MockPostDataSource();
    mockBookmarkDataSource = MockPostBookmarkLocalDataSource();
    repository = PostRepositoryImpl(
      postDataSource: mockDataSource,
      bookmarkLocalDataSource: mockBookmarkDataSource,
    );
  });

  const tUser = User(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
    isVerified: true,
  );

  final tPostModel = PostModel(
    id: 'post-123',
    user: tUser,
    content: 'Test post content',
    mediaUrls: ['https://example.com/image.jpg'],
    likeCount: 10,
    commentCount: 5,
    isLiked: false,
    createdAt: DateTime(2024, 1, 1),
  );

  final tPostList = [tPostModel];

  final tCommentModel = CommentModel(
    id: 'comment-123',
    postId: 'post-123',
    userId: 'user-123',
    username: 'johndoe',
    profilePicUrl: 'https://example.com/profile.jpg',
    content: 'Test comment',
  );

  final tCommentList = [tCommentModel];

  group('createPost', () {
    final tMedia = <PlatformFile>[];
    const tContent = 'Test post content';

    test('should return Right<Post> on success', () async {
      when(
        () => mockDataSource.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenAnswer((_) async => tPostModel);

      final result = await repository.createPost(
        content: tContent,
        media: tMedia,
      );

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (post) => expect(post.id, tPostModel.id),
      );
      verify(
        () => mockDataSource.createPost(content: tContent, media: tMedia),
      ).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenThrow(ServerException('Failed to create post'));

      final result = await repository.createPost(
        content: tContent,
        media: tMedia,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to create post'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when generic exception is thrown', () async {
      when(
        () => mockDataSource.createPost(
          content: any(named: 'content'),
          media: any(named: 'media'),
        ),
      ).thenThrow(Exception('Unexpected error'));

      final result = await repository.createPost(
        content: tContent,
        media: tMedia,
      );

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message.contains('Exception'), true),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('deletePost', () {
    const tPostId = 'post-123';

    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.deletePost(any()),
      ).thenAnswer((_) async => unit);

      final result = await repository.deletePost(tPostId);

      expect(result.isRight(), true);
      verify(() => mockDataSource.deletePost(tPostId)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.deletePost(any()),
      ).thenThrow(ServerException('Failed to delete post'));

      final result = await repository.deletePost(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to delete post'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when post not found', () async {
      when(
        () => mockDataSource.deletePost(any()),
      ).thenThrow(ServerException('Post not found'));

      final result = await repository.deletePost('nonexistent-post');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Post not found'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('toggleLikePost', () {
    const tPostId = 'post-123';

    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.toggleLikePost(any()),
      ).thenAnswer((_) async => unit);

      final result = await repository.toggleLikePost(tPostId);

      expect(result.isRight(), true);
      verify(() => mockDataSource.toggleLikePost(tPostId)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.toggleLikePost(any()),
      ).thenThrow(ServerException('Failed to toggle like'));

      final result = await repository.toggleLikePost(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to toggle like'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when user not authenticated', () async {
      when(
        () => mockDataSource.toggleLikePost(any()),
      ).thenThrow(ServerException('User not authenticated'));

      final result = await repository.toggleLikePost(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not authenticated'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('commentPost', () {
    const tPostId = 'post-123';
    const tComment = 'This is a test comment';

    test('should return Right<Unit> on success', () async {
      when(
        () => mockDataSource.commentPost(any(), any()),
      ).thenAnswer((_) async => unit);

      final result = await repository.commentPost(tPostId, tComment);

      expect(result.isRight(), true);
      verify(() => mockDataSource.commentPost(tPostId, tComment)).called(1);
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.commentPost(any(), any()),
      ).thenThrow(ServerException('Failed to add comment'));

      final result = await repository.commentPost(tPostId, tComment);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to add comment'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when comment is empty', () async {
      when(
        () => mockDataSource.commentPost(any(), any()),
      ).thenThrow(ServerException('Comment cannot be empty'));

      final result = await repository.commentPost(tPostId, '');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Comment cannot be empty'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getPostComments', () {
    const tPostId = 'post-123';

    test('should return Right<List<Comment>> on success', () async {
      when(
        () => mockDataSource.getPostComments(any()),
      ).thenAnswer((_) async => tCommentList);

      final result = await repository.getPostComments(tPostId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (comments) => expect(comments.length, 1),
      );
      verify(() => mockDataSource.getPostComments(tPostId)).called(1);
    });

    test('should return Right with empty list when no comments', () async {
      when(
        () => mockDataSource.getPostComments(any()),
      ).thenAnswer((_) async => <Comment>[]);

      final result = await repository.getPostComments(tPostId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (comments) => expect(comments.isEmpty, true),
      );
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.getPostComments(any()),
      ).thenThrow(ServerException('Failed to fetch comments'));

      final result = await repository.getPostComments(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch comments'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getPosts', () {
    test('should return Right<List<Post>> on success', () async {
      when(
        () => mockDataSource.getPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tPostList);

      final result = await repository.getPosts();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (posts) => expect(posts.length, 1),
      );
      verify(() => mockDataSource.getPosts(page: 1, limit: 20)).called(1);
    });

    test('should return Right<List<Post>> with pagination', () async {
      when(
        () => mockDataSource.getPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tPostList);

      final result = await repository.getPosts(page: 2, limit: 10);

      expect(result.isRight(), true);
      verify(() => mockDataSource.getPosts(page: 2, limit: 10)).called(1);
    });

    test('should return Right with empty list when no posts', () async {
      when(
        () => mockDataSource.getPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => <Post>[]);

      final result = await repository.getPosts();

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (posts) => expect(posts.isEmpty, true),
      );
    });

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.getPosts(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(ServerException('Failed to fetch posts'));

      final result = await repository.getPosts();

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch posts'),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('getUserPosts', () {
    const tUserId = 'user-123';

    test('should return Right<List<Post>> on success', () async {
      when(
        () => mockDataSource.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tPostList);

      final result = await repository.getUserPosts(userId: tUserId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (posts) => expect(posts.length, 1),
      );
      verify(
        () => mockDataSource.getUserPosts(userId: tUserId, page: 1, limit: 20),
      ).called(1);
    });

    test('should return Right<List<Post>> with pagination', () async {
      when(
        () => mockDataSource.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => tPostList);

      final result = await repository.getUserPosts(
        userId: tUserId,
        page: 3,
        limit: 5,
      );

      expect(result.isRight(), true);
      verify(
        () => mockDataSource.getUserPosts(userId: tUserId, page: 3, limit: 5),
      ).called(1);
    });

    test(
      'should return Right with empty list when user has no posts',
      () async {
        when(
          () => mockDataSource.getUserPosts(
            userId: any(named: 'userId'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => <Post>[]);

        final result = await repository.getUserPosts(userId: tUserId);

        expect(result.isRight(), true);
        result.fold(
          (_) => fail('Expected Right'),
          (posts) => expect(posts.isEmpty, true),
        );
      },
    );

    test('should return Left when ServerException is thrown', () async {
      when(
        () => mockDataSource.getUserPosts(
          userId: any(named: 'userId'),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(ServerException('User not found'));

      final result = await repository.getUserPosts(userId: 'nonexistent-user');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not found'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
