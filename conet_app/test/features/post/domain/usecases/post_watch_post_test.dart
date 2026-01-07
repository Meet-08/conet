import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_post.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostWatchPost usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostWatchPost(postRepository: mockPostRepository);
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

  group('PostWatchPost', () {
    const tPostId = 'post-123';

    test('should call watchPost with correct postId', () {
      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.value(tPost));

      usecase(tPostId);

      verify(() => mockPostRepository.watchPost(tPostId)).called(1);
    });

    test('should return Stream<Post>', () {
      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.value(tPost));

      final result = usecase(tPostId);

      expect(result, isA<Stream<Post>>());
    });

    test('should emit post from stream', () async {
      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.value(tPost));

      final stream = usecase(tPostId);
      final post = await stream.first;

      expect(post.id, tPost.id);
      expect(post.content, tPost.content);
    });

    test('should emit updated post data', () async {
      final updatedPost = tPost.copyWith(likeCount: 20, isLiked: true);

      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.fromIterable([tPost, updatedPost]));

      final stream = usecase(tPostId);
      final emissions = await stream.toList();

      expect(emissions.length, 2);
      expect(emissions[0].likeCount, 10);
      expect(emissions[0].isLiked, false);
      expect(emissions[1].likeCount, 20);
      expect(emissions[1].isLiked, true);
    });

    test('should emit comment count changes', () async {
      final updatedPost = tPost.copyWith(commentCount: 10);

      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.fromIterable([tPost, updatedPost]));

      final stream = usecase(tPostId);
      final emissions = await stream.toList();

      expect(emissions[0].commentCount, 5);
      expect(emissions[1].commentCount, 10);
    });

    test('should handle stream errors', () async {
      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.error(Exception('Stream error')));

      final stream = usecase(tPostId);

      expectLater(stream, emitsError(isA<Exception>()));
    });

    test('should watch different posts correctly', () {
      const anotherPostId = 'post-456';

      when(
        () => mockPostRepository.watchPost(any()),
      ).thenAnswer((_) => Stream.value(tPost));

      usecase(tPostId);
      usecase(anotherPostId);

      verify(() => mockPostRepository.watchPost(tPostId)).called(1);
      verify(() => mockPostRepository.watchPost(anotherPostId)).called(1);
    });
  });
}
