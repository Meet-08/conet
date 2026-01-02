import 'dart:io';

import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class PostRepository {
  Future<Either<AppFailure, Post>> createPost({
    required String content,
    required List<File> media,
  });

  Future<Either<AppFailure, Unit>> deletePost(String postId);
  Future<Either<AppFailure, Unit>> toggleLikePost(String postId);
  Future<Either<AppFailure, Unit>> commentPost(String postId, String comment);
  Future<Either<AppFailure, List<Comment>>> getPostComments(String postId);

  Future<Either<AppFailure, List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
  });

  Future<Either<AppFailure, List<Post>>> getUserPosts({
    required String userId,
    int page = 1,
    int limit = 20,
  });

  Stream<List<Post>> watchPosts();
  Stream<Post> watchPost(String postId);
}
