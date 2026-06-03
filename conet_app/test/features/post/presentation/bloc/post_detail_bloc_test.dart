import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_post_comments.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostGetPostComments extends Mock implements PostGetPostComments {}

class MockPostWatchPostComments extends Mock implements PostWatchPostComments {}

class MockPostComment extends Mock implements PostComment {}

class MockPostGetPost extends Mock implements PostGetPost {}

void main() {
  late PostDetailBloc postDetailBloc;
  late MockPostGetPostComments mockGetPostComments;
  late MockPostWatchPostComments mockWatchPostComments;
  late MockPostComment mockCommentPost;
  late MockPostGetPost mockGetPost;

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
    mockWatchPostComments = MockPostWatchPostComments();
    mockCommentPost = MockPostComment();
    mockGetPost = MockPostGetPost();

    when(
      () => mockWatchPostComments(any()),
    ).thenAnswer((_) => Stream<List<Comment>>.value(tCommentList));

    postDetailBloc = PostDetailBloc(
      getPostComments: mockGetPostComments,
      watchPostComments: mockWatchPostComments,
      commentPost: mockCommentPost,
      getPost: mockGetPost,
    );
  });

  tearDown(() {
    postDetailBloc.close();
  });

  test('initial state is PostDetailInitial', () {
    expect(postDetailBloc.state, isA<PostDetailInitial>());
  });

  group('PostDetailWatchCommentsEvent', () {
    const tPostId = 'post-123';

    blocTest<PostDetailBloc, PostDetailState>(
      'emits [PostDetailLoaded] when watch stream emits comments',
      build: () => postDetailBloc,
      act: (bloc) => bloc.add(PostDetailWatchCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'comments length',
          1,
        ),
      ],
      verify: (_) {
        verify(() => mockWatchPostComments(tPostId)).called(1);
      },
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'emits [PostDetailFailure] when watch stream errors',
      build: () {
        when(
          () => mockWatchPostComments(any()),
        ).thenAnswer((_) => Stream<List<Comment>>.error('watch failed'));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailWatchCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailFailure>().having(
          (s) => s.message,
          'message',
          contains('watch failed'),
        ),
      ],
    );
  });

  group('PostDetailAddCommentEvent', () {
    const tPostId = 'post-123';
    const tCommentContent = 'This is a new comment';

    blocTest<PostDetailBloc, PostDetailState>(
      'emits optimistic then refreshed comments on success',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right([...tCommentList, tComment]));
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
          'optimistic comments length',
          2,
        ),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.length,
          'refreshed comments length',
          2,
        ),
      ],
      verify: (_) {
        verify(() => mockCommentPost(tPostId, tCommentContent)).called(1);
        verify(() => mockGetPostComments(tPostId)).called(1);
      },
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'emits optimistic then failure and restarts watch on failure',
      build: () {
        when(
          () => mockCommentPost(any(), any()),
        ).thenAnswer((_) async => Left(AppFailure('Failed to add comment')));
        when(
          () => mockWatchPostComments(any()),
        ).thenAnswer((_) => Stream<List<Comment>>.value(tCommentList));
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
          'Failed to add comment',
        ),
        isA<PostDetailLoaded>(),
      ],
      verify: (_) {
        verify(() => mockCommentPost(tPostId, tCommentContent)).called(1);
        verify(() => mockWatchPostComments(tPostId)).called(greaterThan(0));
      },
    );

    final tReply = Comment(
      id: 'reply-123',
      postId: tPostId,
      userId: 'user-123',
      username: 'replyuser',
      profilePicUrl: '',
      content: 'This is a nested reply',
      parentCommentId: 'comment-123',
    );

    blocTest<PostDetailBloc, PostDetailState>(
      'emits optimistic reply then refreshed comments on success when adding a reply comment',
      build: () {
        when(
          () => mockCommentPost(
            any(),
            any(),
            parentCommentId: any(named: 'parentCommentId'),
          ),
        ).thenAnswer((_) async => const Right(unit));
        when(
          () => mockGetPostComments(any()),
        ).thenAnswer((_) async => Right([
          Comment(
            id: tComment.id,
            postId: tComment.postId,
            userId: tComment.userId,
            username: tComment.username,
            profilePicUrl: tComment.profilePicUrl,
            content: tComment.content,
            parentCommentId: tComment.parentCommentId,
            replies: [tReply],
          )
        ]));
        return postDetailBloc;
      },
      seed: () => PostDetailLoaded([tComment]),
      act: (bloc) => bloc.add(
        PostDetailAddCommentEvent(
          postId: tPostId,
          comment: 'This is a nested reply',
          optimisticComment: tReply,
          parentCommentId: 'comment-123',
        ),
      ),
      expect: () => [
        isA<PostDetailLoaded>().having(
          (s) => s.comments.first.replies.length,
          'optimistic replies length',
          1,
        ).having(
          (s) => s.comments.first.replies.first.id,
          'optimistic reply id',
          'reply-123',
        ),
        isA<PostDetailLoaded>().having(
          (s) => s.comments.first.replies.length,
          'refreshed replies length',
          1,
        ),
      ],
      verify: (_) {
        verify(
          () => mockCommentPost(
            tPostId,
            'This is a nested reply',
            parentCommentId: 'comment-123',
          ),
        ).called(1);
        verify(() => mockGetPostComments(tPostId)).called(1);
      },
    );
  });
}
