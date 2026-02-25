import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/post_bookmark_local_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

class PostRepositoryImpl implements PostRepository {
  final PostDataSource _postDataSource;
  final PostBookmarkLocalDataSource _bookmarkLocalDataSource;

  PostRepositoryImpl({
    required PostDataSource postDataSource,
    required PostBookmarkLocalDataSource bookmarkLocalDataSource,
  }) : _postDataSource = postDataSource,
       _bookmarkLocalDataSource = bookmarkLocalDataSource;

  @override
  Future<Either<AppFailure, Unit>> commentPost(String postId, String comment) {
    return _getResult<Unit>(() => _postDataSource.commentPost(postId, comment));
  }

  @override
  Future<Either<AppFailure, Post>> createPost({
    required String content,
    required List<PlatformFile> media,
  }) {
    return _getResult<Post>(
      () => _postDataSource.createPost(content: content, media: media),
    );
  }

  @override
  Future<Either<AppFailure, Unit>> deletePost(String postId) {
    return _getResult<Unit>(() => _postDataSource.deletePost(postId));
  }

  @override
  Future<Either<AppFailure, Post>> getPost(String postId) {
    return _getResult<Post>(() => _postDataSource.getPost(postId));
  }

  @override
  Future<Either<AppFailure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  }) {
    return _getResult<List<Post>>(
      () => _postDataSource.getPosts(page: page, limit: limit),
    );
  }

  @override
  Future<Either<AppFailure, List<Post>>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) {
    return _getResult<List<Post>>(
      () => _postDataSource.getUserPosts(
        userId: userId,
        page: page,
        limit: limit,
      ),
    );
  }

  @override
  Future<Either<AppFailure, List<Comment>>> getPostComments(String postId) {
    return _getResult<List<Comment>>(
      () => _postDataSource.getPostComments(postId),
    );
  }

  @override
  Stream<List<Comment>> watchPostComments(String postId) {
    return _postDataSource.watchPostComments(postId);
  }

  @override
  Future<Either<AppFailure, Unit>> toggleLikePost(String postId) {
    return _getResult<Unit>(() => _postDataSource.toggleLikePost(postId));
  }

  // ---------------------------------------------------------------------------
  // Bookmark operations (local only — no network involved)
  // ---------------------------------------------------------------------------

  @override
  Future<Either<AppFailure, Unit>> bookmarkPost(Post post) async {
    try {
      await _bookmarkLocalDataSource.bookmarkPost(post);
      return const Right(unit);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, Unit>> removeBookmark(String postId) async {
    try {
      await _bookmarkLocalDataSource.removeBookmark(postId);
      return const Right(unit);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Post>>> getBookmarkedPosts() async {
    try {
      final posts = await _bookmarkLocalDataSource.getBookmarkedPosts();
      return Right(posts);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, bool>> isPostBookmarked(String postId) async {
    try {
      final result = await _bookmarkLocalDataSource.isPostBookmarked(postId);
      return Right(result);
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, List<Post>>> getLikedPosts({
    int page = 1,
    int limit = 20,
  }) {
    return _getResult<List<Post>>(
      () => _postDataSource.getLikedPosts(page: page, limit: limit),
    );
  }

  Future<Either<AppFailure, T>> _getResult<T>(Future<T> Function() fn) async {
    try {
      return Right(await fn());
    } on ServerException catch (e) {
      return Left(AppFailure(e.message));
    } catch (e) {
      return Left(AppFailure(e.toString()));
    }
  }
}
