import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_delete.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostDelete usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostDelete(postRepository: mockPostRepository);
  });

  group('PostDelete', () {
    const tPostId = 'post-123';

    test('should call deletePost with correct postId', () async {
      when(
        () => mockPostRepository.deletePost(any()),
      ).thenAnswer((_) async => const Right(unit));

      await usecase(tPostId);

      verify(() => mockPostRepository.deletePost(tPostId)).called(1);
    });

    test('should return Right<Unit> on success', () async {
      when(
        () => mockPostRepository.deletePost(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(tPostId);

      expect(result, const Right(unit));
    });

    test('should return Left<AppFailure> on failure', () async {
      final tFailure = AppFailure('Post not found');
      when(
        () => mockPostRepository.deletePost(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure.message, 'Post not found'),
        (_) => fail('Expected Left'),
      );
    });

    test('should return Left when unauthorized to delete', () async {
      final tFailure = AppFailure('Unauthorized to delete this post');
      when(
        () => mockPostRepository.deletePost(any()),
      ).thenAnswer((_) async => Left(tFailure));

      final result = await usecase(tPostId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) =>
            expect(failure.message, 'Unauthorized to delete this post'),
        (_) => fail('Expected Left'),
      );
    });
  });
}
