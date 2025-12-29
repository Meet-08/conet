import 'package:conet_app/core/error/app_failure.dart';
import 'package:conet_app/feature/post/domain/entities/post.dart';
import 'package:conet_app/feature/post/domain/repositories/post_repository.dart';
import 'package:fpdart/fpdart.dart';

class PostGetUserPosts {
  final PostRepository _postRepository;

  PostGetUserPosts({required PostRepository postRepository})
    : _postRepository = postRepository;

  Future<Either<AppFailure, List<Post>>> call({
    required String userId,
    int page = 1,
    int limit = 20,
  }) {
    return _postRepository.getUserPosts(
      userId: userId,
      page: page,
      limit: limit,
    );
  }
}
