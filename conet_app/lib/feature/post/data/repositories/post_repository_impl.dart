import 'dart:io';

import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/core/error/server_exception.dart';
import 'package:conet_app/feature/post/data/data_sources/post_data_source.dart';
import 'package:conet_app/feature/post/data/data_sources/post_real_time_data_source.dart';
import 'package:conet_app/feature/post/domain/entities/comment.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostRepositoryImpl implements PostRepository {
  final PostDataSource _postDataSource;
  final PostRealtimeDataSource _postRealtimeSource;

  PostRepositoryImpl({
    required PostDataSource postDataSource,
    required PostRealtimeDataSource postRealtimeSource,
  }) : _postDataSource = postDataSource,
       _postRealtimeSource = postRealtimeSource;

  @override
  Future<Either<AppFailure, Unit>> commentPost(String postId, String comment) {
    return _getResult<Unit>(() => _postDataSource.commentPost(postId, comment));
  }

  @override
  Future<Either<AppFailure, Post>> createPost({
    required String content,
    required List<File> media,
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
  Future<Either<AppFailure, Unit>> toggleLikePost(String postId) {
    return _getResult<Unit>(() => _postDataSource.toggleLikePost(postId));
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

  @override
  Stream<Post> watchPost(String postId) {
    return _postRealtimeSource.watchPost(postId);
  }

  @override
  Stream<List<Post>> watchPosts() {
    return _postRealtimeSource.watchPosts();
  }
}
