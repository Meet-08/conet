import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_post_comments.dart';
import 'package:conet_app/feature/post/presentation/bloc/post_detail_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostGetPostComments extends Mock implements PostGetPostComments {}

class MockPostWatchPostComments extends Mock implements PostWatchPostComments {}

class MockPostComment extends Mock implements PostComment {}

void main() {
  late PostDetailBloc postDetailBloc;
  late MockPostGetPostComments mockGetPostComments;
  late MockPostWatchPostComments mockWatchPostComments;
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
    mockWatchPostComments = MockPostWatchPostComments();
    mockCommentPost = MockPostComment();

    when(
      () => mockWatchPostComments(any()),
    ).thenAnswer((_) => Stream<List<Comment>>.value(tCommentList));

    postDetailBloc = PostDetailBloc(
      getPostComments: mockGetPostComments,
      watchPostComments: mockWatchPostComments,
      commentPost: mockCommentPost,
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
      'emits [PostDetailLoading, PostDetailLoaded] when watch stream emits comments',
      build: () => postDetailBloc,
      act: (bloc) => bloc.add(PostDetailWatchCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoading>(),
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
      'emits [PostDetailLoading, PostDetailFailure] when watch stream errors',
      build: () {
        when(
          () => mockWatchPostComments(any()),
        ).thenAnswer((_) => Stream<List<Comment>>.error('watch failed'));
        return postDetailBloc;
      },
      act: (bloc) => bloc.add(PostDetailWatchCommentsEvent(postId: tPostId)),
      expect: () => [
        isA<PostDetailLoading>(),
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
        isA<PostDetailLoading>(),
        isA<PostDetailLoaded>(),
      ],
      verify: (_) {
        verify(() => mockCommentPost(tPostId, tCommentContent)).called(1);
        verify(() => mockWatchPostComments(tPostId)).called(greaterThan(0));
      },
    );
  });
}
