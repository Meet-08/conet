import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_toggle_like.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostToggleLike usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostToggleLike(postRepository: mockPostRepository);
  });

  group('PostToggleLike', () {
    const tPostId = 'post-123';

    test('should call toggleLikePost with correct postId', () async {
      when(
        () => mockPostRepository.toggleLikePost(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tPostId);

      verify(() => mockPostRepository.toggleLikePost(tPostId)).called(1);
    });

    test('should return Right<Unit> on success (like)', () async {
      when(
        () => mockPostRepository.toggleLikePost(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tPostId);

      expect(result, const Right(unit));
    });

    test('should return Right<Unit> on success (unlike)', () async {
      when(
        () => mockPostRepository.toggleLikePost(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tPostId);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Failed to toggle like');
      when(
        () => mockPostRepository.toggleLikePost(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Failed to toggle like'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when user not authenticated', () async {
      final tFailure = AppFailure('User not authenticated');
      when(
        () => mockPostRepository.toggleLikePost(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'User not authenticated'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when post not found', () async {
      final tFailure = AppFailure('Post not found');
      when(
        () => mockPostRepository.toggleLikePost(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase('nonexistent-post');

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Post not found'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
