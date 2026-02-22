import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_bookmark.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_create.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_bookmarks.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_user_posts.dart';
import 'package:conet_app/feature/post/domain/usecases/post_remove_bookmark.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostGetPosts extends Mock implements PostGetPosts {}

class MockPostCreate extends Mock implements PostCreate {}

class MockPostDelete extends Mock implements PostDelete {}

class MockPostToggleLike extends Mock implements PostToggleLike {}

class MockPostComment extends Mock implements PostComment {}

class MockPostGetPostComments extends Mock implements PostGetPostComments {}

class MockPostGetUserPosts extends Mock implements PostGetUserPosts {}

class MockPostBookmark extends Mock implements PostBookmark {}

class MockPostRemoveBookmark extends Mock implements PostRemoveBookmark {}

class MockPostGetBookmarks extends Mock implements PostGetBookmarks {}

class MockPlatformFile extends Mock implements PlatformFile {}

void main() {
  late PostBloc postBloc;
  late MockPostGetPosts mockGetPosts;
  late MockPostGetUserPosts mockGetUserPosts;
  late MockPostCreate mockCreatePost;
  late MockPostDelete mockDeletePost;
  late MockPostToggleLike mockToggleLike;
  late MockPostComment mockCommentPost;
  late MockPostGetPostComments mockGetPostComments;
  late MockPostBookmark mockBookmarkPost;
  late MockPostRemoveBookmark mockRemoveBookmark;
  late MockPostGetBookmarks mockGetBookmarks;

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

  setUp(() {
    mockGetPosts = MockPostGetPosts();
    mockGetUserPosts = MockPostGetUserPosts();
    mockCreatePost = MockPostCreate();
    mockDeletePost = MockPostDelete();
    mockToggleLike = MockPostToggleLike();
    mockCommentPost = MockPostComment();
    mockGetPostComments = MockPostGetPostComments();
    mockBookmarkPost = MockPostBookmark();
    mockRemoveBookmark = MockPostRemoveBookmark();
    mockGetBookmarks = MockPostGetBookmarks();

    // Default stub: no bookmarks (prevents unhandled mock calls)
    when(
      () => mockGetBookmarks(),
    ).thenAnswer((_) async => const Right(<Post>[]));

    postBloc = PostBloc(
      getPosts: mockGetPosts,
      getUserPosts: mockGetUserPosts,
      createPost: mockCreatePost,
      deletePost: mockDeletePost,
      toggleLike: mockToggleLike,
      commentPost: mockCommentPost,
      getPostComments: mockGetPostComments,
      bookmarkPost: mockBookmarkPost,
      removeBookmark: mockRemoveBookmark,
      getBookmarks: mockGetBookmarks,
    );
  });

  setUpAll(() {
    registerFallbackValue(<PlatformFile>[]);
  });

  tearDown(() {
    postBloc.close();
  });

  test('initial state is PostInitial', () {
    expect(postBloc.state, isA<PostInitial>());
  });

  group('PostGetPostsEvent', () {
    blocTest<PostBloc, PostState>(
      'emits [PostLoading, PostLoaded] when getPosts succeeds',
      build: () {
        when(
          () => mockGetPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Right(tPostList));
        return postBloc;
      },
      act: (bloc) => bloc.add(const PostGetPostsEvent(page: 1, limit: 20)),
      expect: () => [
        isA<PostLoading>(),
        isA<PostLoaded>().having((s) => s.posts, 'posts', tPostList),
      ],
      verify: (_) {
        verify(() => mockGetPosts(page: 1, limit: 20)).called(1);
      },
    );

    blocTest<PostBloc, PostState>(
      'emits [PostLoading, PostFailure] when getPosts fails',
      build: () {
        when(
          () => mockGetPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to fetch posts')));
        return postBloc;
      },
      act: (bloc) => bloc.add(const PostGetPostsEvent(page: 1, limit: 20)),
      expect: () => [
        isA<PostLoading>(),
        isA<PostFailure>().having(
          (s) => s.message,
          'message',
          'Failed to fetch posts',
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'emits PostLoaded with empty list when no posts',
      build: () {
        when(
          () => mockGetPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<Post>[]));
        return postBloc;
      },
      act: (bloc) => bloc.add(const PostGetPostsEvent(page: 1, limit: 20)),
      expect: () => [
        isA<PostLoading>(),
        isA<PostLoaded>().having(
          (s) => s.posts.isEmpty,
          'posts is empty',
          true,
        ),
      ],
    );
  });

  group('PostCreatePostEvent', () {
    const tContent = 'New post content';
    final tMedia = <PlatformFile>[];

    blocTest<PostBloc, PostState>(
      'calls createPost with correct parameters',
      build: () {
        when(
          () => mockCreatePost(
            content: any(named: 'content'),
            media: any(named: 'media'),
          ),
        ).thenAnswer((_) async => Right(tPost));
        return postBloc;
      },
      act: (bloc) =>
          bloc.add(PostCreatePostEvent(content: tContent, media: tMedia)),
      verify: (_) {
        verify(
          () => mockCreatePost(content: tContent, media: tMedia),
        ).called(1);
      },
    );

    blocTest<PostBloc, PostState>(
      'emits PostFailure when createPost fails',
      build: () {
        when(
          () => mockCreatePost(
            content: any(named: 'content'),
            media: any(named: 'media'),
          ),
        ).thenAnswer((_) async => Left(AppFailure('Failed to create post')));
        return postBloc;
      },
      act: (bloc) =>
          bloc.add(PostCreatePostEvent(content: tContent, media: tMedia)),
      expect: () => [
        isA<PostFailure>().having(
          (s) => s.message,
          'message',
          'Failed to create post',
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'does not emit failure on success',
      build: () {
        when(
          () => mockCreatePost(
            content: any(named: 'content'),
            media: any(named: 'media'),
          ),
        ).thenAnswer((_) async => Right(tPost));
        return postBloc;
      },
      act: (bloc) =>
          bloc.add(PostCreatePostEvent(content: tContent, media: tMedia)),
      expect: () => [
        isA<PostLoaded>()
            .having((s) => s.posts, 'posts', [tPost])
            .having((s) => s.recentlyCreated, 'recentlyCreated', true),
      ],
    );
  });

  group('PostDeletePostEvent', () {
    const tPostId = 'post-123';

    blocTest<PostBloc, PostState>(
      'calls deletePost with correct postId',
      build: () {
        when(
          () => mockDeletePost(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      act: (bloc) => bloc.add(const PostDeletePostEvent(postId: tPostId)),
      verify: (_) {
        verify(() => mockDeletePost(tPostId)).called(1);
      },
    );

    blocTest<PostBloc, PostState>(
      'emits PostFailure when deletePost fails',
      build: () {
        when(
          () => mockDeletePost(any()),
        ).thenAnswer((_) async => Left(AppFailure('Failed to delete post')));
        return postBloc;
      },
      act: (bloc) => bloc.add(const PostDeletePostEvent(postId: tPostId)),
      expect: () => [
        isA<PostFailure>().having(
          (s) => s.message,
          'message',
          'Failed to delete post',
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'does not emit failure on success',
      build: () {
        when(
          () => mockDeletePost(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      act: (bloc) => bloc.add(const PostDeletePostEvent(postId: tPostId)),
      expect: () => [],
    );
  });

  group('PostToggleLikePostEvent', () {
    const tPostId = 'post-123';

    blocTest<PostBloc, PostState>(
      'optimistically updates like and calls toggleLike',
      build: () {
        when(
          () => mockToggleLike(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      seed: () => PostLoaded(tPostList),
      act: (bloc) => bloc.add(const PostToggleLikePostEvent(postId: tPostId)),
      expect: () => [
        isA<PostLoaded>().having(
          (s) => s.posts.first.isLiked,
          'first post isLiked',
          true,
        ),
      ],
      verify: (_) {
        verify(() => mockToggleLike(tPostId)).called(1);
      },
    );

    blocTest<PostBloc, PostState>(
      'optimistically increments like count when liking',
      build: () {
        when(
          () => mockToggleLike(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      seed: () => PostLoaded(tPostList),
      act: (bloc) => bloc.add(const PostToggleLikePostEvent(postId: tPostId)),
      expect: () => [
        isA<PostLoaded>().having(
          (s) => s.posts.first.likeCount,
          'first post likeCount',
          11, // was 10, now 11
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'optimistically decrements like count when unliking',
      build: () {
        when(
          () => mockToggleLike(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      seed: () => PostLoaded([tPost.copyWith(isLiked: true, likeCount: 10)]),
      act: (bloc) => bloc.add(const PostToggleLikePostEvent(postId: tPostId)),
      expect: () => [
        isA<PostLoaded>().having(
          (s) => s.posts.first.likeCount,
          'first post likeCount',
          9, // was 10, now 9
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'rolls back on failure',
      build: () {
        when(
          () => mockToggleLike(any()),
        ).thenAnswer((_) async => Left(AppFailure('Failed to toggle like')));
        return postBloc;
      },
      seed: () => PostLoaded(tPostList),
      act: (bloc) => bloc.add(const PostToggleLikePostEvent(postId: tPostId)),
      expect: () => [
        isA<PostLoaded>().having(
          (s) => s.posts.first.isLiked,
          'first post isLiked after optimistic update',
          true,
        ),
        isA<PostLoaded>().having(
          (s) => s.posts.first.isLiked,
          'first post isLiked after rollback',
          false, // rolled back
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'does nothing if state is not PostLoaded',
      build: () {
        when(
          () => mockToggleLike(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      // Initial state is PostInitial, not PostLoaded
      act: (bloc) => bloc.add(const PostToggleLikePostEvent(postId: tPostId)),
      expect: () => [],
      verify: (_) {
        verifyNever(() => mockToggleLike(any()));
      },
    );
  });

  group('PostCommentEvent', () {
    const tPostId = 'post-123';
    const tComment = 'This is a test comment';

    blocTest<PostBloc, PostState>(
      'calls commentPost with correct parameters',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      act: (bloc) =>
          bloc.add(const PostCommentEvent(postId: tPostId, comment: tComment)),
      verify: (_) {
        verify(() => mockCommentPost(tPostId, tComment)).called(1);
      },
    );

    blocTest<PostBloc, PostState>(
      'emits PostFailure when commentPost fails',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => Left(AppFailure('Failed to add comment')));
        return postBloc;
      },
      act: (bloc) =>
          bloc.add(const PostCommentEvent(postId: tPostId, comment: tComment)),
      expect: () => [
        isA<PostFailure>().having(
          (s) => s.message,
          'message',
          'Failed to add comment',
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'does not emit failure on success',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      act: (bloc) =>
          bloc.add(const PostCommentEvent(postId: tPostId, comment: tComment)),
      expect: () => [],
    );
  });

  group('Multiple posts handling', () {
    final tPost2 = Post(
      id: 'post-456',
      user: tUser,
      content: 'Second post',
      mediaUrls: [],
      likeCount: 5,
      commentCount: 2,
      isLiked: true,
      createdAt: DateTime(2024, 1, 2),
    );

    final multiplePosts = [tPost, tPost2];

    blocTest<PostBloc, PostState>(
      'only updates the targeted post when toggling like',
      build: () {
        when(
          () => mockToggleLike(any()),
        ).thenAnswer((_) async => const Right(unit));
        return postBloc;
      },
      seed: () => PostLoaded(multiplePosts),
      act: (bloc) =>
          bloc.add(const PostToggleLikePostEvent(postId: 'post-123')),
      expect: () => [
        isA<PostLoaded>().having(
          (s) {
            final first = s.posts.firstWhere((p) => p.id == 'post-123');
            final second = s.posts.firstWhere((p) => p.id == 'post-456');
            return first.isLiked &&
                second.isLiked; // first toggled, second unchanged
          },
          'only first post toggled',
          true,
        ),
      ],
    );
  });

  group('PostSyncCommentCountEvent', () {
    final tPost2 = Post(
      id: 'post-456',
      user: tUser,
      content: 'Second post',
      mediaUrls: [],
      likeCount: 5,
      commentCount: 2,
      isLiked: true,
      createdAt: DateTime(2024, 1, 2),
    );

    final multiplePosts = [tPost, tPost2];

    blocTest<PostBloc, PostState>(
      'updates only targeted post comment count',
      build: () => postBloc,
      seed: () => PostLoaded(multiplePosts),
      act: (bloc) => bloc.add(
        const PostSyncCommentCountEvent(postId: 'post-123', commentCount: 9),
      ),
      expect: () => [
        isA<PostLoaded>().having(
          (s) {
            final first = s.posts.firstWhere((p) => p.id == 'post-123');
            final second = s.posts.firstWhere((p) => p.id == 'post-456');
            return first.commentCount == 9 && second.commentCount == 2;
          },
          'targeted post updated only',
          true,
        ),
      ],
    );

    blocTest<PostBloc, PostState>(
      'does nothing when not in PostLoaded state',
      build: () => postBloc,
      act: (bloc) => bloc.add(
        const PostSyncCommentCountEvent(postId: 'post-123', commentCount: 9),
      ),
      expect: () => [],
    );
  });
}
