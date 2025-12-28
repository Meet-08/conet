import 'dart:convert';
import 'dart:io';

import 'package:conet_app/core/api/dio_client.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/file_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/data/models/post_model.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/main.dart';
import 'package:fpdart/src/unit.dart';
import 'package:uuid/uuid.dart';

class PostDataSourceImpl implements PostDataSource {
  final FileDataSource fileDataSource;
  final DioClient dioClient;

  PostDataSourceImpl({required this.fileDataSource, required this.dioClient});

  @override
  Future<Post> createPost({
    required String content,
    required List<File> media,
  }) async {
    String postId = const Uuid().v4();
    try {
      final mediaUrls = await fileDataSource.uploadFiles(
        postId: postId,
        files: media,
      );

      final res = await dioClient.dio.post(
        "/post",
        data: {"postId": postId, "content": content, "mediaUrls": mediaUrls},
      );

      if (res.statusCode != 201) throw ServerException("Post creation failed");
      final data = jsonDecode(res.data) as Map<String, dynamic>;
      logger.i("Post created $data");
      return PostModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Unit> commentPost(String postId) {
    // TODO: implement commentPost
    throw UnimplementedError();
  }

  @override
  Future<Unit> deletePost(String postId) async {
    logger.i("Deleting post $postId");
    final res = await dioClient.dio.delete("/post", data: {"postId": postId});
    if (res.statusCode != 200) throw ServerException("Failed to delete post");
    logger.i("Post deleted $postId");
    return unit;
  }

  @override
  Future<List<Post>> getPosts({int page = 1, int limit = 20}) async {
    final res = await dioClient.dio.get(
      "/post",
      queryParameters: {"page": page, "limit": limit},
    );
    if (res.statusCode != 200) throw ServerException("Failed to get posts");
    final data = jsonDecode(res.data) as Map<String, dynamic>;
    return data['posts'].map((e) => PostModel.fromJson(e)).toList();
  }

  @override
  Future<List<Post>?> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  }) {
    // TODO: implement getUserPosts
    throw UnimplementedError();
  }

  @override
  Future<Unit> likePost(String postId) {
    // TODO: implement likePost
    throw UnimplementedError();
  }
}
