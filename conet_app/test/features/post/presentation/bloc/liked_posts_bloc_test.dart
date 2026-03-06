import 'package:bloc_test/bloc_test.dart';
import 'package:conet_app/core/common/entities/user.dart';
import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/usecases/post_get_liked_posts.dart';
import 'package:conet_app/feature/post/presentation/bloc/liked_posts_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockPostGetLikedPosts extends Mock implements PostGetLikedPosts {}

void main() {
  late LikedPostsBloc bloc;
  late MockPostGetLikedPosts mockGetLikedPosts;

  const tUser = User(
    id: 'user-123',
    email: 'test@example.com',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
    profilePicUrl: '',
    userRole: UserRole.user,
  );

  final tPost = Post(
    id: 'post-123',
    user: tUser,
    content: 'Test post content',
    mediaUrls: ['https://example.com/image.jpg'],
    likeCount: 10,
    commentCount: 5,
    isLiked: true,
    createdAt: DateTime(2024, 1, 1),
  );

  final tPostList = [tPost];

  setUp(() {
    mockGetLikedPosts = MockPostGetLikedPosts();
    bloc = LikedPostsBloc(getLikedPosts: mockGetLikedPosts);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is LikedPostsInitial', () {
    expect(bloc.state, isA<LikedPostsInitial>());
  });

  group('LikedPostsFetchEvent', () {
    blocTest<LikedPostsBloc, LikedPostsState>(
      'emits [LikedPostsLoading, LikedPostsLoaded] when fetch succeeds',
      build: () {
        when(
          () => mockGetLikedPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Right(tPostList));
        return bloc;
      },
      act: (bloc) => bloc.add(const LikedPostsFetchEvent()),
      expect: () => [
        isA<LikedPostsLoading>(),
        isA<LikedPostsLoaded>().having((s) => s.posts, 'posts', tPostList),
      ],
      verify: (_) {
        verify(() => mockGetLikedPosts(page: 1, limit: 20)).called(1);
      },
    );

    blocTest<LikedPostsBloc, LikedPostsState>(
      'emits [LikedPostsLoading, LikedPostsFailure] when fetch fails',
      build: () {
        when(
          () => mockGetLikedPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer(
          (_) async => Left(AppFailure('Failed to fetch liked posts')),
        );
        return bloc;
      },
      act: (bloc) => bloc.add(const LikedPostsFetchEvent()),
      expect: () => [
        isA<LikedPostsLoading>(),
        isA<LikedPostsFailure>().having(
          (s) => s.message,
          'message',
          'Failed to fetch liked posts',
        ),
      ],
    );

    blocTest<LikedPostsBloc, LikedPostsState>(
      'emits LikedPostsLoaded with empty list when no liked posts',
      build: () {
        when(
          () => mockGetLikedPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(<Post>[]));
        return bloc;
      },
      act: (bloc) => bloc.add(const LikedPostsFetchEvent()),
      expect: () => [
        isA<LikedPostsLoading>(),
        isA<LikedPostsLoaded>().having(
          (s) => s.posts.isEmpty,
          'posts is empty',
          true,
        ),
      ],
    );

    blocTest<LikedPostsBloc, LikedPostsState>(
      'emits LikedPostsLoaded with correct posts on custom pagination',
      build: () {
        when(
          () => mockGetLikedPosts(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => Right(tPostList));
        return bloc;
      },
      act: (bloc) => bloc.add(const LikedPostsFetchEvent(page: 2, limit: 10)),
      expect: () => [
        isA<LikedPostsLoading>(),
        isA<LikedPostsLoaded>().having((s) => s.posts, 'posts', tPostList),
      ],
      verify: (_) {
        verify(() => mockGetLikedPosts(page: 2, limit: 10)).called(1);
      },
    );
  });
}
