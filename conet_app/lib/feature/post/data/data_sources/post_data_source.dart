import 'dart:core';

import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fpdart/fpdart.dart';

abstract class PostDataSource {
  Future<Post> createPost({
    required String content,
    required List<PlatformFile> media,
  });

  Future<Post> getPost(String postId);

  Future<List<Post>> getPosts({int page = 1, int limit = 20});

  Future<List<Post>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  Future<Unit> deletePost(String postId);

  Future<Unit> toggleLikePost(String postId);

  Future<Unit> commentPost(String postId, String comment, {String? parentCommentId});

  Future<List<Comment>> getPostComments(String postId);

  Stream<List<Comment>> watchPostComments(String postId);

  Future<List<Post>> getLikedPosts({int page = 1, int limit = 20});

  Future<Unit> recordImpressions(List<String> postIds);
}
