import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/data/models/comment_model.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

class PostDataSourceImpl implements PostDataSource {
  final FileDataSource fileDataSource;
  final DioClient dioClient;

  PostDataSourceImpl({required this.fileDataSource, required this.dioClient});

  @override
  Future<Post> createPost({
    required String content,
    required List<PlatformFile> media,
  }) async {
    String postId = const Uuid().v4();
    try {
      final mediaUrls = await fileDataSource.uploadFiles(
        postId: postId,
        files: media,
      );

      final res = await dioClient.dio.post(
        "/posts",
        data: {"content": content, "media_urls": mediaUrls},
      );

      if (res.statusCode != 201) throw ServerException("Post creation failed");
      final data = res.data as Map<String, dynamic>;
      logger.i("Post created $data");
      return PostModel.fromJson(data['post']);
    } catch (e) {
      logger.e("Failed to create post", error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> commentPost(String postId, String comment) async {
    try {
      logger.i("Commenting on post $postId");
      final res = await dioClient.dio.post(
        "/posts/comment/$postId",
        data: {"content": comment},
      );
      if (res.statusCode != 201) {
        throw ServerException("Failed to comment on post");
      }
      logger.i("Post commented $postId");
      return unit;
    } catch (e) {
      logger.e("Failed to comment on post $postId", error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Comment>> getPostComments(String postId) async {
    try {
      logger.i("Getting comments for post $postId");
      final res = await dioClient.dio.get("/posts/$postId/comments");
      if (res.statusCode != 200) {
        throw ServerException("Failed to get comments for post");
      }
      logger.i("Post comments $postId");
      final data = res.data as Map<String, dynamic>;
      logger.i("Post comments $data");
      final comments = data['comments'] as List;
      return comments.map((e) => CommentModel.fromJson(e)).toList();
    } catch (e) {
      logger.e("Failed to get comments for post $postId", error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> deletePost(String postId) async {
    try {
      logger.i("Deleting post $postId");
      final res = await dioClient.dio.delete("/posts/$postId");
      if (res.statusCode != 200) throw ServerException("Failed to delete post");
      logger.i("Post deleted $postId");
      return unit;
    } catch (e) {
      logger.e("Failed to delete post $postId", error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Post>> getPosts({int page = 1, int limit = 20}) async {
    try {
      final res = await dioClient.dio.get(
        "/posts",
        queryParameters: {"page": page, "limit": limit},
      );
      if (res.statusCode != 200) throw ServerException("Failed to get posts");
      final data = res.data as Map<String, dynamic>;
      final posts = data['posts'] as List;
      return posts.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      logger.e("Failed to get posts", error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Post>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await dioClient.dio.get(
        "/posts/user/$userId",
        queryParameters: {"page": page, "limit": limit},
      );
      if (res.statusCode != 200) throw ServerException("Failed to get posts");
      final data = res.data as Map<String, dynamic>;
      final posts = data['posts'] as List;
      return posts.map((e) => PostModel.fromJson(e)).toList();
    } catch (e) {
      logger.e("Failed to get posts for user $userId", error: e);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> toggleLikePost(String postId) async {
    try {
      logger.i("Liking post $postId");
      final res = await dioClient.dio.put("/posts/like/$postId");
      if (res.statusCode != 200) throw ServerException("Failed to like post");
      logger.i("Post liked $postId");
      return unit;
    } catch (e) {
      logger.e("Failed to toggle like on post $postId", error: e);
      throw ServerException(e.toString());
    }
  }
}
