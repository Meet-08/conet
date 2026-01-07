import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:conet_app/feature/post/domain/usecases/post_watch_posts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPostRepository extends Mock implements PostRepository {}

void main() {
  late PostWatchPosts usecase;
  late MockPostRepository mockPostRepository;

  setUp(() {
    mockPostRepository = MockPostRepository();
    usecase = PostWatchPosts(postRepository: mockPostRepository);
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

  final tPostList = [tPost];

  group('PostWatchPosts', () {
    test('should call watchPosts on repository', () {
      when(
        () => mockPostRepository.watchPosts(),
      ).thenAnswer((_) => Stream.value(tPostList));

      usecase();

      verify(() => mockPostRepository.watchPosts()).called(1);
    });

    test('should return Stream<List<Post>>', () {
      when(
        () => mockPostRepository.watchPosts(),
      ).thenAnswer((_) => Stream.value(tPostList));

      final result = usecase();

      expect(result, isA<Stream<List<Post>>>());
    });

    test('should emit posts from stream', () async {
      when(
        () => mockPostRepository.watchPosts(),
      ).thenAnswer((_) => Stream.value(tPostList));

      final stream = usecase();
      final posts = await stream.first;

      expect(posts.length, 1);
      expect(posts.first.id, tPost.id);
    });

    test('should emit empty list when no posts', () async {
      when(
        () => mockPostRepository.watchPosts(),
      ).thenAnswer((_) => Stream.value(<Post>[]));

      final stream = usecase();
      final posts = await stream.first;

      expect(posts.isEmpty, true);
    });

    test('should emit multiple updates', () async {
      final updatedPostList = [tPost.copyWith(likeCount: 20)];

      when(
        () => mockPostRepository.watchPosts(),
      ).thenAnswer((_) => Stream.fromIterable([tPostList, updatedPostList]));

      final stream = usecase();
      final emissions = await stream.toList();

      expect(emissions.length, 2);
      expect(emissions[0].first.likeCount, 10);
      expect(emissions[1].first.likeCount, 20);
    });

    test('should handle stream errors', () async {
      when(
        () => mockPostRepository.watchPosts(),
      ).thenAnswer((_) => Stream.error(Exception('Stream error')));

      final stream = usecase();

      expectLater(stream, emitsError(isA<Exception>()));
    });
  });
}
