import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostGetPostComments extends Mock implements PostGetPostComments {}

class MockPostComment extends Mock implements PostComment {}

void main() {
  late PostDetailBloc postDetailBloc;
  late MockPostGetPostComments mockGetPostComments;
  late MockPostComment mockCommentPost;

  final tComment = Comment(
    id: 'comment-123',
    postId: 'post-123',
    userId: 'user-123',
    username: 'johndoe',
    profilePicUrl: 'https://example.com/profile.jpg',
    content: 'Test comment',
  );

  final tCommentList = [tComment];

  setUp(() {
    mockGetPostComments = MockPostGetPostComments();
    mockCommentPost = MockPostComment();

    postDetailBloc = PostDetailBloc(
      getPostComments: mockGetPostComments,
      commentPost: mockCommentPost,
    );
  });

  tearDown(() {
    postDetailBloc.close();
  });

  test('initial state is PostDetailInitial', () {
    expect(postDetailBloc.state, isA<PostDetailInitial>());
  });

  group('PostDetailGetCommentsEvent', () {
    const tPostId = 'post-123';

    blocTest<PostDetailBloc, PostDetailState>(
      'emits [PostDetailLoading, PostDetailLoaded] when getPostComments succeeds',
      build: () {
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(tCommentList));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailGetCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'comments length',
          1,
        ),
      ],
      verify: (_) {
        verify(() => mockGetPostComments(tPostId)).called(1);
      },
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'emits [PostDetailLoading, PostDetailFailure] when getPostComments fails',
      build: () {
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Left(AppFailure('Failed to fetch comments')));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailGetCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoading>(),
        isA<PostDetailFailure>().having(
          (s) => s.message,
          'message',
          'Failed to fetch comments',
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'emits PostDetailLoaded with empty list when no comments',
      build: () {
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => const Right(<Comment>[]));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailGetCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.isEmpty,
          'comments is empty',
          true,
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'loads multiple comments correctly',
      build: () {
        final multipleComments = [
          Comment(
            id: 'comment-1',
            postId: tPostId,
            userId: 'user-1',
            username: 'user1',
            profilePicUrl: null,
            content: 'First comment',
          ),
          Comment(
            id: 'comment-2',
            postId: tPostId,
            userId: 'user-2',
            username: 'user2',
            profilePicUrl: null,
            content: 'Second comment',
          ),
          Comment(
            id: 'comment-3',
            postId: tPostId,
            userId: 'user-3',
            username: 'user3',
            profilePicUrl: null,
            content: 'Third comment',
          ),
        ];
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(multipleComments));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailGetCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'comments length',
          3,
        ),
      ],
    );
  });

  group('PostDetailAddCommentEvent', () {
    const tPostId = 'post-123';
    const tCommentContent = 'This is a new comment';

    blocTest<PostDetailBloc, PostDetailState>(
      'emits optimistic PostDetailLoaded and nothing else on success',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => const Right(unit));
        // No reload needed
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded(tCommentList),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: tPostId,
          comment: tCommentContent,
          optimisticComment: tComment,
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'comments length',
          2, // tCommentList (1) + optimistic (1)
        ),
      ],
      verify: (_) {
        verify(() => mockCommentPost(tPostId, tCommentContent)).called(1);
        verifyNever(() => mockGetPostComments(any())); // No reload on success
      },
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'emits optimistic PostDetailLoaded then PostDetailFailure then reload when commentPost fails logic',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => Left(AppFailure('Failed to add comment')));
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(tCommentList));
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded(tCommentList),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: tPostId,
          comment: tCommentContent,
          optimisticComment: tComment,
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>(), // Optimistic update
        isA<PostDetailFailure>().having(
          (s) => s.message,
          'message',
          'Failed to add comment',
        ),
        isA<PostDetailLoading>(), // Reload
        isA<PostDetailLoaded>(), // Reload result
      ],
      verify: (_) {
        verify(() => mockCommentPost(tPostId, tCommentContent)).called(1);
        verify(() => mockGetPostComments(tPostId)).called(1); // Reload happened
      },
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'handles empty comment gracefully (server should reject)',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => Left(AppFailure('Comment cannot be empty')));
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(tCommentList));
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded(tCommentList),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: tPostId,
          comment: '',
          optimisticComment: tComment,
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>(),
        isA<PostDetailFailure>().having(
          (s) => s.message,
          'message',
          'Comment cannot be empty',
        ),
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>(),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'handles user not authenticated error',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => Left(AppFailure('User not authenticated')));
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(tCommentList));
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded(tCommentList),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: tPostId,
          comment: tCommentContent,
          optimisticComment: tComment,
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>(),
        isA<PostDetailFailure>().having(
          (s) => s.message,
          'message',
          'User not authenticated',
        ),
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>(),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'handles post not found error',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => Left(AppFailure('Post not found')));
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(tCommentList));
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded(tCommentList),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: 'nonexistent-post',
          comment: tCommentContent,
          optimisticComment: tComment,
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>(),
        isA<PostDetailFailure>().having(
          (s) => s.message,
          'message',
          'Post not found',
        ),
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>(),
      ],
    );
  });

  group('Sequential operations', () {
    const tPostId = 'post-123';

    blocTest<PostDetailBloc, PostDetailState>(
      'can load comments for different posts',
      build: () {
        when(
          () => mockGetPostComments('post-123'),
        ).thenAnswer((_) async => Right(tCommentList));
        when(
          () => mockGetPostComments('post-456'),
        ).thenAnswer((_) async => const Right(<Comment>[]));
        return postDetailBloc;
      },
      act: (bloc) async {
        bloc.add(PostDetailGetCommentsEvent(postId: 'post-123'));
        await Future.delayed(const Duration(milliseconds: 100));
        bloc.add(PostDetailGetCommentsEvent(postId: 'post-456'));
      },
      expect: () => [
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'comments for first post',
          1,
        ),
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.isEmpty,
          'comments for second post is empty',
          true,
        ),
      ],
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'add comment and immediately shows updated comments because of optimistic update',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => const Right(unit));
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded(tCommentList),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: tPostId,
          comment: 'New comment',
          optimisticComment: tComment,
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'comments length',
          2, // 1 existing + 1 optimistic
        ),
      ],
    );
  });

  group('State preservation', () {
    blocTest<PostDetailBloc, PostDetailState>(
      'does not preserve state between different post loads',
      build: () {
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right(tCommentList));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailGetCommentsEvent(postId: 'post-123')),
      expect: () => [
        isA<PostDetailLoading>(), // old state is replaced
        isA<PostDetailLoaded>(),
      ],
    );
  });
}
