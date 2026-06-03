import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PostRepository {
  Future<Either<AppFailure, Post>> createPost({
    required String content,
    required List<PlatformFile> media,
  });

  Future<Either<AppFailure, Unit>> deletePost(String postId);
  Future<Either<AppFailure, Post>> getPost(String postId);
  Future<Either<AppFailure, Unit>> toggleLikePost(String postId);
  Future<Either<AppFailure, Unit>> commentPost(String postId, String comment, {String? parentCommentId});
  Future<Either<AppFailure, List<Comment>>> getPostComments(String postId);
  Stream<List<Comment>> watchPostComments(String postId);

  Future<Either<AppFailure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  });

  Future<Either<AppFailure, List<Post>>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  // Bookmark operations (local only)
  Future<Either<AppFailure, Unit>> bookmarkPost(Post post);
  Future<Either<AppFailure, Unit>> removeBookmark(String postId);
  Future<Either<AppFailure, List<Post>>> getBookmarkedPosts();
  Future<Either<AppFailure, bool>> isPostBookmarked(String postId);

  Future<Either<AppFailure, List<Post>>> getLikedPosts({
    int page = 1,
    int limit = 20,
  });

  Future<Either<AppFailure, Unit>> recordImpressions(List<String> postIds);
}
