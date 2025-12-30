import 'dart:core';
import 'dart:io';

import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:fpdart/fpdart.dart';

abstract class PostDataSource {
  Future<Post> createPost({required String content, required List<File> media});

  Future<List<Post>> getPosts({int page = 1, int limit = 20});

  Future<List<Post>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  Future<Unit> deletePost(String postId);

  Future<Unit> toggleLikePost(String postId);

  Future<Unit> commentPost(String postId, String comment);
}
