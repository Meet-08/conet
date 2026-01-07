import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_post_comments.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostGetPostComments usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostGetPostComments(postRepository: mockPostRepository);
  });

  final tComment = Comment(
    id: 'comment-123',
    postId: 'post-123',
    userId: 'user-123',
    username: 'johndoe',
    profilePicUrl: 'https://example.com/profile.jpg',
    content: 'Test comment',
  );

  final tCommentList = [tComment];

  group('PostGetPostComments', () {
    const tPostId = 'post-123';

    test('should call getPostComments with correct postId', () async {
      when(
        () => mockPostRepository.getPostComments(any()),
      ).thenAnswer((_) async => Right(tCommentList));

      await usecase(tPostId);

      verify(() => mockPostRepository.getPostComments(tPostId)).called(1);
    });

    test('should return Right<List<Comment>> on success', () async {
      when(
        () => mockPostRepository.getPostComments(any()),
      ).thenAnswer((_) async => Right(tCommentList));

      final result = await usecase(tPostId);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (comments) {
        expect(comments.length, 1);
        expect(comments.first.id, tComment.id);
      });
    });

    test('should return Right with empty list when no comments', () async {
      when(
        () => mockPostRepository.getPostComments(any()),
      ).thenAnswer((_) async => const Right(<Comment>[]));

      final result = await usecase(tPostId);

      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Expected Right'),
        (comments) => expect(comments.isEmpty, true),
      );
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to fetch comments');
      when(
        () => mockPostRepository.getPostComments(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to fetch comments'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when post not found', () async {
      final tFailure = AppFailure('Post not found');
      when(
        () => mockPostRepository.getPostComments(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase('nonexistent-post');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Post not found'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return multiple comments in order', () async {
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
      ];

      when(
        () => mockPostRepository.getPostComments(any()),
      ).thenAnswer((_) async => Right(multipleComments));

      final result = await usecase(tPostId);

      expect(result.isRight(), true);
      result.fold((_) => fail('Expected Right'), (comments) {
        expect(comments.length, 2);
        expect(comments[0].content, 'First comment');
        expect(comments[1].content, 'Second comment');
      });
    });
  });
}
