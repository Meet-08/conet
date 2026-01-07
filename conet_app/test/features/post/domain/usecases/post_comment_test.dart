import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_comment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostComment usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostComment(postRepository: mockPostRepository);
  });

  group('PostComment', () {
    const tPostId = 'post-123';
    const tComment = 'This is a test comment';

    test('should call commentPost with correct params', () async {
      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tPostId, tComment);

      verify(() => mockPostRepository.commentPost(tPostId, tComment)).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tPostId, tComment);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to add comment');
      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId, tComment);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to add comment'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when post not found', () async {
      final tFailure = AppFailure('Post not found');
      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase('nonexistent-post', tComment);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Post not found'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when user not authenticated', () async {
      final tFailure = AppFailure('User not authenticated');
      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId, tComment);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not authenticated'),
        (_) => fail('Expected Left'),
      );
    });

    test('should handle long comments', () async {
      final longComment = 'A' * 1000; // 1000 character comment

      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tPostId, longComment);

      expect(result, const Right(unit));
      verify(
        () => mockPostRepository.commentPost(tPostId, longComment),
      ).called(1);
    });

    test('should handle special characters in comment', () async {
      const specialComment = 'Comment with émojis 🎉 and spëcial çharacters!';

      when(
        () => mockPostRepository.commentPost(any(), any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tPostId, specialComment);

      expect(result, const Right(unit));
    });
  });
}
